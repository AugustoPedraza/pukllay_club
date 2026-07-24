defmodule PukllayClub.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PukllayClubWeb.Telemetry,
      PukllayClub.Repo,
      {DNSCluster, query: Application.get_env(:pukllay_club, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PukllayClub.PubSub},
      # Start a worker by calling: PukllayClub.Worker.start_link(arg)
      # {PukllayClub.Worker, arg},
      # Start to serve requests, typically the last entry
      PukllayClubWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PukllayClub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PukllayClubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
