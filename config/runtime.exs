import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/pukllay_club start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :pukllay_club, PukllayClubWeb.Endpoint, server: true
end

config :pukllay_club, PukllayClubWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# Sentry DSN comes from the runtime env only — never a literal value in git.
# Unset (dev/test) leaves dsn nil, which disables reporting entirely.
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: config_env()

if config_env() == :dev do
  # Mirror Credentials' R2_PUBLIC_BASE_URL fallback chain (env var, then
  # dev.secret.exs's Application config) here rather than in config/dev.exs,
  # because compile-time config (including dev.secret.exs, imported at the
  # bottom of dev.exs) isn't merged into Application env until after
  # dev.exs finishes evaluating — dev.exs can only ever see the env var.
  # By runtime.exs, dev.secret.exs's config IS visible, so this is the only
  # point that can resolve the same R2 host the seed pipeline actually used.
  dev_r2_public_base_url =
    System.get_env("R2_PUBLIC_BASE_URL") ||
      Application.get_env(:pukllay_club, PukllayClub.Catalog.Seed, [])[:r2_public_base_url]

  # Reload browser tabs when matching files change.
  config :pukllay_club, PukllayClubWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        # Static assets, except user uploads
        ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
        # Gettext translations
        ~r"priv/gettext/.*\.po$",
        # Router, Controllers, LiveViews and LiveComponents
        ~r"lib/pukllay_club_web/router\.ex$",
        ~r"lib/pukllay_club_web/(controllers|live|components)/.*\.(ex|heex)$"
      ]
    ]

  if dev_r2_public_base_url do
    uri = URI.parse(dev_r2_public_base_url)
    port_suffix = if uri.port in [nil, 80, 443], do: "", else: ":#{uri.port}"
    config :pukllay_club, :image_origin, "#{uri.scheme}://#{uri.host}#{port_suffix}"
  end
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  # The CSP img-src origin (01-06/T-01-28) — scheme+host only, derived from
  # the same R2_PUBLIC_BASE_URL the D-02 seed pipeline's Credentials module
  # mints every stored image URL from, so the policy can never drift from
  # where the club's images actually live. Required at boot (like
  # DATABASE_URL/SECRET_KEY_BASE above) rather than defaulted, because a
  # silently-missing origin would just quietly block every cover/gallery
  # image in the browser instead of failing loudly at deploy time.
  r2_public_base_url =
    System.get_env("R2_PUBLIC_BASE_URL") ||
      raise """
      environment variable R2_PUBLIC_BASE_URL is missing.
      Required to scope the Content-Security-Policy img-src directive to the
      club's actual R2 image host (see PukllayClubWeb.CSP). This is a public
      URL, not a secret — add it to config/deploy.yml's env.clear block and
      .kamal/secrets (or set it as a literal, non-secret value) before the
      next deploy.
      """

  image_origin =
    case URI.parse(r2_public_base_url) do
      %URI{scheme: scheme, host: host, port: port} when port in [nil, 80, 443] ->
        "#{scheme}://#{host}"

      %URI{scheme: scheme, host: host, port: port} ->
        "#{scheme}://#{host}:#{port}"
    end

  # The detail page's reservation CTA (SHELL-03, D-09/D-10, plan 01.1-05)
  # deep-links to the club's real WhatsApp number via wa.me — a published
  # business number, not a secret, but still required at boot (like
  # DATABASE_URL/R2_PUBLIC_BASE_URL above) rather than defaulted, so a
  # missing value fails loudly instead of shipping a dead reservation CTA.
  # This is a DIFFERENT WhatsApp destination from PukllayClubWeb.ClubLinks'
  # group-invite URL — never resolve it through that module.
  reservation_whatsapp_number =
    System.get_env("RESERVATION_WHATSAPP_NUMBER") ||
      raise """
      environment variable RESERVATION_WHATSAPP_NUMBER is missing.
      Required for the detail page's reservation CTA to deep-link to the
      club's real WhatsApp number. This is a published business number, not
      a secret — add it to config/deploy.yml's env.clear block before the
      next deploy.
      """

  normalized_reservation_number = String.replace(reservation_whatsapp_number, ~r/\D/, "")

  config :pukllay_club, PukllayClub.Repo,
    # ACCEPTED RISK (WR-04, 00-REVIEW.md): TLS is intentionally disabled here.
    # App <-> db traffic (including DATABASE_URL's embedded credentials)
    # crosses the unencrypted Docker bridge network between the app and `db`
    # accessory containers on the single-tenant deploy host — the accessory's
    # host port is bound to 127.0.0.1 in config/deploy.yml, but that only
    # governs host-level exposure, not this inter-container path. Accepted
    # as low-risk for a single-tenant host today; revisit (ssl: true with a
    # self-signed accessory cert) if the deploy topology ever becomes
    # multi-tenant or the host is shared.
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  config :pukllay_club, PukllayClubWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  config :pukllay_club, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
  config :pukllay_club, :image_origin, image_origin

  if normalized_reservation_number == "" do
    raise """
    environment variable RESERVATION_WHATSAPP_NUMBER contains no digits
    after normalization (got: #{inspect(reservation_whatsapp_number)}).
    Expected an international phone number, digits only or with spaces/
    dashes/a leading '+' that normalize away to digits.
    """
  end

  config :pukllay_club, :reservation_whatsapp_number, normalized_reservation_number

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :pukllay_club, PukllayClubWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :pukllay_club, PukllayClubWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :pukllay_club, PukllayClub.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://swoosh.hexdocs.pm/Swoosh.html#module-installation for details.
end
