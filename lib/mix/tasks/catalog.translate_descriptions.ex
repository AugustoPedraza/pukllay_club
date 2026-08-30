defmodule Mix.Tasks.Catalog.TranslateDescriptions do
  @shortdoc "One-time Spanish translation of every game description via Gemini (D-01)"
  @moduledoc """
  For every `games` row whose stored `bgg_payload` carries an English
  description, calls Gemini once (via InstructorLite,
  `PukllayClub.Catalog.Seed.DescriptionTranslator`) to produce a Spanish
  translation and writes it to the `description` column.

  This is a one-time, manually-run, developer-machine job — never an Oban
  job, never called at request time. `PROJECT.md`'s durable architecture
  principle ("never an LLM call on the request hot path") is unaffected:
  this job runs entirely outside any request cycle, once, on a developer
  machine.

      mix catalog.translate_descriptions [--limit N] [--dry-run] [--only-english]

  `--limit N` processes only the first N candidate games (ordered by id,
  so a partial run can be resumed by re-running with a higher limit or no
  limit at all). `--dry-run` still calls Gemini and reports the outcome,
  but writes nothing to the database. `--only-english` skips any
  candidate whose currently stored `description` already differs from its
  cleaned English payload source — i.e. games this job (or a prior run of
  it) has already translated — so a resumed run doesn't re-spend Gemini
  quota re-translating games that are already done.

  The English source is always read from `bgg_payload`'s `description`
  entry, never from the `description` column being written — this is what
  makes the job idempotent: the column is the output, the payload entry is
  the pristine input, and re-running never re-translates an
  already-translated string.

  On any per-game failure (missing/malformed Gemini response, network
  error), the game's existing description is left untouched and the batch
  continues to the next game — one failure never aborts the run. Writes a
  Markdown run record to
  `priv/repo/seed_data/description_translation_report.md` naming the run
  timestamp, the model used, the attempted/translated/failed counts, and
  every failure's game id and reason.
  """
  use Mix.Task

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.DescriptionNormalizer
  alias PukllayClub.Catalog.Seed.DescriptionTranslator
  alias PukllayClub.Repo

  @report_relative_path "priv/repo/seed_data/description_translation_report.md"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args, strict: [limit: :integer, dry_run: :boolean, only_english: :boolean])

    Mix.Task.run("app.start")

    credentials = Credentials.fetch!()
    Mix.shell().info("Translation credentials: #{inspect(Credentials.redacted(credentials))}")

    dry_run? = Keyword.get(opts, :dry_run, false)
    only_english? = Keyword.get(opts, :only_english, false)

    candidates =
      candidate_games()
      |> Enum.filter(&(source_text(&1) != nil))
      |> maybe_filter_only_english(only_english?)
      |> maybe_limit(opts[:limit])

    {attempted, translated, failures} = run_batch(candidates, credentials, dry_run?)

    Mix.shell().info("Translation complete: #{translated}/#{attempted} translated, #{length(failures)} failed.")

    write_report!(attempted, translated, failures)
  end

  defp candidate_games do
    Game
    |> where([g], not is_nil(g.bgg_payload))
    |> order_by([g], asc: g.id)
    |> Repo.all()
  end

  defp source_text(game), do: get_in(game.bgg_payload, ["description"])

  defp maybe_filter_only_english(games, false), do: games

  defp maybe_filter_only_english(games, true) do
    Enum.filter(games, fn game -> DescriptionNormalizer.clean(source_text(game)) == game.description end)
  end

  defp maybe_limit(games, nil), do: games
  defp maybe_limit(games, limit), do: Enum.take(games, limit)

  defp run_batch(candidates, credentials, dry_run?) do
    {attempted, translated, failures} =
      Enum.reduce(candidates, {0, 0, []}, fn game, {attempted, translated, failures} ->
        case translate_and_write(game, credentials, dry_run?) do
          :ok ->
            {attempted + 1, translated + 1, failures}

          {:error, reason} ->
            Mix.shell().error("Translation failed for game id #{game.id}: #{inspect(reason)}")
            {attempted + 1, translated, [{game.id, reason} | failures]}
        end
      end)

    {attempted, translated, Enum.reverse(failures)}
  end

  defp translate_and_write(game, credentials, dry_run?) do
    with {:ok, spanish_text} <- DescriptionTranslator.translate(source_text(game), credentials) do
      write_translation(game, spanish_text, dry_run?)
    end
  end

  defp write_translation(_game, _spanish_text, true = _dry_run?), do: :ok

  defp write_translation(game, spanish_text, false = _dry_run?) do
    game
    |> Ecto.Changeset.cast(%{description: spanish_text}, [:description])
    |> Repo.update()
    |> case do
      {:ok, _game} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp write_report!(attempted, translated, failures) do
    report_path = Path.join(File.cwd!(), @report_relative_path)
    File.mkdir_p!(Path.dirname(report_path))
    File.write!(report_path, report_content(attempted, translated, failures))
    Mix.shell().info("Report written to #{report_path}")
  end

  defp report_content(attempted, translated, failures) do
    """
    # Description Translation Report

    Run at: #{DateTime.to_iso8601(DateTime.utc_now())}
    Model: #{DescriptionTranslator.default_model()}

    - Attempted: #{attempted}
    - Translated: #{translated}
    - Failed: #{length(failures)}

    ## Failures

    #{format_failures(failures)}
    """
  end

  defp format_failures([]), do: "None."

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn {id, reason} -> "- id #{id}: #{inspect(reason)}" end)
  end
end
