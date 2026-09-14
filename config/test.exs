import Config

# Print only warnings and errors during test
config :logger, level: :warning

# Only in tests, remove the complexity from the password hashing algorithm
config :pbkdf2_elixir, :rounds, 1

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Oban runs in manual testing mode (Oban.Testing) — jobs are inserted but
# never auto-executed by a real queue; tests call `perform_job/2` explicitly.
config :pukllay_club, Oban, testing: :manual

# Obviously-fake credentials for the D-02 catalog seed pipeline so its unit
# tests run in CI without real BGG/R2 access, with a stable URL host to
# assert against.
config :pukllay_club, PukllayClub.Catalog.Seed,
  bgg_api_token: "test-token",
  r2_account_id: "test-account-id",
  r2_access_key_id: "test-access-key-id",
  r2_secret_access_key: "test-secret-access-key",
  r2_catalog_bucket: "test-catalog-bucket",
  r2_public_base_url: "https://images.test.invalid",
  gemini_api_key: "test-gemini-key"

# In test we don't send emails
config :pukllay_club, PukllayClub.Mailer, adapter: Swoosh.Adapters.Test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :pukllay_club, PukllayClub.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pukllay_club_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pukllay_club, PukllayClubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/jp505oA2jS6YW9vBIneYjeMB1F8YEMt9hqm0T6qNg99pzFDKECOfjQy+2LhvJJi",
  server: false

# Routes the seed pipeline's outbound HTTP through Req.Test stubs so its
# unit tests never touch the network (see BggClient.req_options/0 and
# ImagePipeline.req_options/0).
config :pukllay_club, :bgg_req_options, plug: {Req.Test, PukllayClub.Catalog.Seed.BggClient}
config :pukllay_club, :image_download_req_options, plug: {Req.Test, PukllayClub.Catalog.Seed.ImagePipeline}

# The CSP img-src origin (01-06/T-01-28) — same host as the Seed
# r2_public_base_url above, so tests exercise the exact origin the policy
# would scope to in a real environment.
config :pukllay_club, :image_origin, "https://images.test.invalid"

# Test placeholder for the detail page's reservation CTA (plan 01.1-05) —
# not a real number. config/runtime.exs's :prod block raises instead of
# falling back to this value, so this placeholder can never reach production.
config :pukllay_club, :reservation_whatsapp_number, "5491100000000"

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
