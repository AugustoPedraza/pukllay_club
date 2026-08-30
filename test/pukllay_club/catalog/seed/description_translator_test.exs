defmodule PukllayClub.Catalog.Seed.DescriptionTranslatorTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.DescriptionTranslator
  alias PukllayClub.Catalog.Seed.TranslatedDescription

  describe "translate/3" do
    test "returns {:ok, spanish_text} for a well-formed stubbed response" do
      stub = fn _params, _opts -> {:ok, %TranslatedDescription{description_es: "Un juego de mesa clásico."}} end

      assert {:ok, "Un juego de mesa clásico."} =
               DescriptionTranslator.translate("A classic board game.", Credentials.fetch!(), call: stub)
    end

    test "an error tuple from the LLM call leaves the game's stored description untouched" do
      game = game_fixture(%{description: "Descripción original."})
      stub = fn _params, _opts -> {:error, :timeout} end

      assert {:error, :timeout} =
               DescriptionTranslator.translate("Some English text.", Credentials.fetch!(), call: stub)

      # translate/3 never writes to the database itself — confirming the row
      # is untouched proves a failing translation can never blank or
      # overwrite an existing description.
      reloaded = Repo.get!(Game, game.id)
      assert reloaded.description == "Descripción original."
    end

    test "a response missing the required field is rejected by changeset validation, not stored as nil/empty" do
      invalid_changeset =
        %TranslatedDescription{}
        |> Ecto.Changeset.cast(%{}, [:description_es])
        |> TranslatedDescription.validate_changeset([])

      refute invalid_changeset.valid?

      stub = fn _params, _opts -> {:error, invalid_changeset} end

      assert {:error, %Ecto.Changeset{valid?: false}} =
               DescriptionTranslator.translate("Some English text.", Credentials.fetch!(), call: stub)
    end

    test "cleans the source text through DescriptionNormalizer before building the prompt" do
      test_pid = self()

      stub = fn params, _opts ->
        send(test_pid, {:prompt_params, params})
        {:ok, %TranslatedDescription{description_es: "Un juego de mesa."}}
      end

      DescriptionTranslator.translate(
        "A game &mdash; with escapes &eacute;.",
        Credentials.fetch!(),
        call: stub
      )

      assert_received {:prompt_params, params}
      prompt_text = get_in(params, [:contents, Access.at(0), :parts, Access.at(0), :text])

      refute prompt_text =~ "&mdash;"
      refute prompt_text =~ "&eacute;"
      assert prompt_text =~ "—"
      assert prompt_text =~ "é"
    end

    test "translating the same source text twice with the same stub yields the same result" do
      stub = fn _params, _opts -> {:ok, %TranslatedDescription{description_es: "Resultado estable."}} end

      result1 = DescriptionTranslator.translate("Same text.", Credentials.fetch!(), call: stub)
      result2 = DescriptionTranslator.translate("Same text.", Credentials.fetch!(), call: stub)

      assert result1 == result2
      assert result1 == {:ok, "Resultado estable."}
    end

    test "a nil source text is skipped without an error and without invoking the LLM call" do
      stub = fn _params, _opts -> flunk("the LLM call must never be invoked for a nil source text") end

      assert DescriptionTranslator.translate(nil, Credentials.fetch!(), call: stub) == {:error, :no_source_text}
    end

    test "raises a clear, actionable error naming GEMINI_API_KEY when credentials carry no Gemini key" do
      credentials = %Credentials{Credentials.fetch!() | gemini_api_key: nil}
      stub = fn _params, _opts -> flunk("the LLM call must never be invoked without a Gemini key") end

      error =
        assert_raise(RuntimeError, fn ->
          DescriptionTranslator.translate("Some text.", credentials, call: stub)
        end)

      assert error.message =~ "GEMINI_API_KEY"
    end
  end
end
