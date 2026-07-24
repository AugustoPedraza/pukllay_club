defmodule PukllayClub.Repo do
  use Ecto.Repo,
    otp_app: :pukllay_club,
    adapter: Ecto.Adapters.Postgres
end
