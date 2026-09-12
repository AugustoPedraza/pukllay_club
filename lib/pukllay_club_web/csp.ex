defmodule PukllayClubWeb.CSP do
  @moduledoc """
  Builds the Content-Security-Policy header value applied to every
  `:browser`-piped response via `PukllayClubWeb.Router`'s private `put_csp/2`
  plug (T-01-28) — closing Phase 0's deferred Sobelow `Config.CSP` finding
  (see `.sobelow-conf`) now that Phase 1 has real page content to scope a
  policy against.

  `img-src`'s extra origin comes from the single `:pukllay_club,
  :image_origin` application key, set in `config/{dev,test,runtime}.exs`
  from the same `R2_PUBLIC_BASE_URL` source the D-02 seed pipeline's
  `PukllayClub.Catalog.Seed.Credentials.r2_object_url/2` mints every stored
  image URL from — so the policy can never drift from where the club's
  images actually live. Never hardcode a literal r2.dev/BGG hostname here.

  `frame-src` (plan 01.4-12, G-01.4-5, D-12) is the app's first and only
  third-party frame origin. It exists solely for the About page's Contacto
  map (`about_live.ex`'s live embedded map) and its value is derived
  from `PukllayClubWeb.ClubLinks.maps_embed_origin/0`, so this directive
  can never name a host the iframe does not actually load. `frame-ancestors
  'none'` is untouched and unrelated: that directive governs who may frame
  THIS app, not whom this app may frame — a distinction the G-01.4-4 debug
  session had to establish explicitly
  (`.planning/debug/resolved/G-01.4-4-maps-thumbnail-approach.md`).
  Widening this value, or adding a second frame origin, needs its own
  decision. Same rule as `img-src` above, extended to this directive: never
  hardcode a literal hostname here, in code or in prose — a hostname
  written into this module would be a second source of truth that can
  silently disagree with the first. Resolve it only through
  `ClubLinks.maps_embed_origin/0`.

  `script-src` (phase 01.8, SEC-05) carries a per-request nonce appended
  inside this same directive's value — never a new directive. The nonce is
  generated once per HTTP request by the router's `put_csp/2` plug (the
  only source of truth for it) and passed into `policy/1` as an argument,
  so this module never reads it from process state or a second call site.
  `'unsafe-inline'` was never present on `script-src` before this refactor
  and is not being introduced by it — the nonce is additive, not a
  weakening.
  """

  @doc "Builds the full Content-Security-Policy header value for `nonce`."
  @spec policy(String.t()) :: String.t()
  def policy(nonce) do
    Enum.join(
      [
        "default-src 'self'",
        img_src(),
        "style-src 'self' 'unsafe-inline'",
        script_src(nonce),
        frame_src(),
        "font-src 'self'",
        "connect-src 'self' ws: wss:",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'"
      ],
      "; "
    )
  end

  # `data:` covers inline SVG/placeholder assets; the configured image
  # origin is appended only when present so a boot-time misconfiguration
  # degrades to a stricter-than-necessary policy (no cover images) rather
  # than crashing every request.
  defp img_src do
    case Application.get_env(:pukllay_club, :image_origin) do
      origin when is_binary(origin) and origin != "" -> "img-src 'self' data: #{origin}"
      _missing -> "img-src 'self' data:"
    end
  end

  # See the moduledoc's `script-src` paragraph. The nonce arrives as an
  # argument, never read from process state — the same "never a second
  # source of truth" rule `img_src/0`/`frame_src/0` already enforce.
  defp script_src(nonce) do
    "script-src 'self' 'nonce-#{nonce}'"
  end

  # See the moduledoc's `frame-src` paragraph. Computed, not a literal in
  # the directive list above — the same shape as `img_src/0`.
  defp frame_src do
    "frame-src #{PukllayClubWeb.ClubLinks.maps_embed_origin()}"
  end
end
