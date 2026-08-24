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
  """

  @doc "Builds the full Content-Security-Policy header value."
  @spec policy() :: String.t()
  def policy do
    Enum.join(
      [
        "default-src 'self'",
        img_src(),
        "style-src 'self' 'unsafe-inline'",
        "script-src 'self'",
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
end
