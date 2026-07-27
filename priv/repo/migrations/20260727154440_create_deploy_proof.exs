defmodule PukllayClub.Repo.Migrations.CreateDeployProof do
  use Ecto.Migration

  @moduledoc """
  D-06 live migration proof (plan 00-05, Task 3): a trivial, real
  schema-change migration shipped through the full CI -> build -> Kamal
  pipeline to confirm the new container only serves traffic after
  `bin/migrate` succeeds. No application code reads this table — it exists
  solely to be observed in `schema_migrations` on the live host.
  """

  def change do
    create table(:deploy_proof) do
      add :note, :string
    end
  end
end
