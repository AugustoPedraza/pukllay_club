# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  pukllay_club: [
    args:
      ~w(js/app.js js/theme.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Oban (D-01, 01.8.1-06): the app's first background job runner. Concurrency
# of 1 on the `enrichment` queue bounds image-processing (libvips) memory on
# the 1 GB production e2-micro host — running two enrichment jobs at once
# risked OOM on that box. Pruner keeps `oban_jobs` from growing unbounded
# (completed/cancelled/discarded jobs older than 7 days are removed).
config :pukllay_club, Oban,
  engine: Oban.Engines.Basic,
  repo: PukllayClub.Repo,
  queues: [enrichment: 1],
  plugins: [{Oban.Plugins.Pruner, max_age: 604_800}]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :pukllay_club, PukllayClub.Mailer, adapter: Swoosh.Adapters.Local

# Configure the endpoint
config :pukllay_club, PukllayClubWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  # 01.1-07: renders through the root layout (head/body/stylesheet/theme
  # script/lang="es") rather than with no layout wrapper at all, so an
  # error page inherits the app's real <head> instead of declaring a
  # second one that could drift from it. This is {PukllayClubWeb.Layouts,
  # :root} — root.html.heex only, NOT Layouts.app/1 — the error views have
  # no LiveView assigns (nav_links/nav_search/current_scope/etc.)
  # Layouts.app's slots need.
  render_errors: [
    formats: [html: PukllayClubWeb.ErrorHTML, json: PukllayClubWeb.ErrorJSON],
    layout: {PukllayClubWeb.Layouts, :root}
  ],
  pubsub_server: PukllayClub.PubSub,
  live_view: [signing_salt: "dmrfmHVT"]

# Single source for the outbound sender identity (D-36) — UserNotifier reads
# this via Application.fetch_env!/2 rather than hardcoding a `from` tuple, so
# the address is declared exactly once across every environment.
config :pukllay_club, :mail_from, {"Pukllay Club", "no-responder@pukllay.club"}

config :pukllay_club, :scopes,
  user: [
    default: true,
    module: PukllayClub.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: PukllayClub.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :pukllay_club,
  ecto_repos: [PukllayClub.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure Sentry crash reporting. The DSN itself is sourced from the
# SENTRY_DSN runtime env var (config/runtime.exs) — never a literal value
# here or in git. When SENTRY_DSN is unset (local dev/test), Sentry's `dsn`
# stays nil and no events are ever sent.
config :sentry,
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  pukllay_club: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
