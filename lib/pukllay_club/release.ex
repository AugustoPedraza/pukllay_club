defmodule PukllayClub.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :pukllay_club

  def createdb do
    load_app()

    for repo <- repos() do
      case ensure_repo_created(repo) do
        :ok -> :ok
        {:error, term} -> raise "failed to create storage for #{inspect(repo)}: #{inspect(term)}"
      end
    end
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Creates the club owner account (D-32) from a release shell, over SSH:

      bin/pukllay_club eval 'PukllayClub.Release.create_owner("owner@example.com")'

  Delegates to `PukllayClub.Accounts.create_owner/1` inside
  `Ecto.Migrator.with_repo/2` (the same wrapper `migrate/0` already uses)
  since a release has no running application supervision tree by default.
  Prints a confirmation on success, or the changeset errors on failure, and
  returns the underlying `Accounts.create_owner/1` result.
  """
  def create_owner(email) do
    load_app()

    {:ok, result, _} =
      Ecto.Migrator.with_repo(PukllayClub.Repo, fn _repo ->
        PukllayClub.Accounts.create_owner(email)
      end)

    case result do
      {:ok, user} -> IO.puts("Owner creado: #{user.email}")
      {:error, changeset} -> IO.puts("No se pudo crear el owner: #{inspect(changeset.errors)}")
    end

    result
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end

  defp ensure_repo_created(repo) do
    case repo.__adapter__().storage_up(repo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end
end
