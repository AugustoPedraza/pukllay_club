defmodule PukllayClubWeb.SentryScrubber do
  @moduledoc """
  Redacts user-supplied values out of `Sentry.LiveViewHook`'s breadcrumbs
  before they leave this server.

  `Sentry.LiveViewHook` records a breadcrumb for every mount, `handle_params`
  and `handle_event`, and the breadcrumb's `data` carries the raw params. That
  is precisely what makes the hook worth having — and precisely what makes it
  a data-egress path that needs a deliberate policy rather than the SDK
  default.

  ## Why the hook exists at all

  Sentry `ELIXIR-1` was a `FunctionClauseError` in
  `PukllayClubWeb.CatalogLive.Show.handle_event/3` whose event name and params
  were **not** in the payload, so the report named the module's *first* clause
  (a whole-function clause mismatch always does) and said nothing about which
  event actually failed. Diagnosing it took a full enumeration of every event
  the page can dispatch plus a read of LiveView's shipped client source; see
  `.planning/debug/resolved/catalog-show-no-clause.md`. A breadcrumb carrying
  the event name and the param *keys* would have answered it in seconds.

  ## Why the default scrubber is not enough

  `Sentry.Scrubber`'s defaults key off credential-shaped names —
  `password`, `passwd`, `secret`. The reservation modal's field is named
  `nombre`, and a `phx-blur` on it arrives under the key `value` (LiveView's
  `extractMeta` copies a non-`<form>` element's native `.value` there). Neither
  name looks like a credential, so both would sail past the default scrubber
  and a club member's typed name would reach a third-party service. `show.ex`
  builds the reservation link **entirely server-side** for exactly this reason
  (threat `T-01.1-02`); shipping the same name to Sentry through a debugging
  convenience would quietly undo that.

  ## The policy: keep the keys, drop the values

  Redact the *values* of `nombre` and `value`; keep the key names and the event
  name. This is the whole point of the split:

    * The event name and the param **keys** are the entire diagnostic payload
      for a clause mismatch. `%{event: "validate-reservation", params:
      %{"value" => "*********"}}` tells you immediately that the client sent
      `"value"` — which is the bug. Dropping the keys instead would leave
      `params: %{}`, indistinguishable from an event with no params at all,
      and the hook would not have solved `ELIXIR-1` either.
    * The typed value contributes **nothing** to diagnosing a clause mismatch.
      It is pure user data with no diagnostic upside, so it never leaves here.

  Redacting `"value"` costs no diagnostic signal anywhere else in the app.
  `validate-reservation` is the only handler in `lib/` that reads a `"value"`
  param; every other control deliberately names its bindings `facet` /
  `scalar` / `choice` / `url`, because a `phx-value-value` binding is silently
  clobbered by that same `extractMeta` line (see `filter_modal.ex`'s
  moduledoc). On those controls `"value"` is already ignored noise.

  Do not "simplify" this module into the default scrubber, and do not swap the
  redaction for a `Map.drop/2`. The first leaks member names; the second
  destroys the signal the hook was added to capture.

  > #### Scope {: .info}
  >
  > This covers breadcrumb `data` only. The endpoint's LiveView socket declares
  > `connect_info: [session: ...]` and deliberately **not** `:peer_data` or
  > `:user_agent`, so the hook never populates Sentry's user-IP or user-agent
  > context in the first place.
  """

  # Composed on top of the SDK defaults rather than replacing them: the `:keys`
  # option OVERRIDES the default list, so `default_param_keys/0` has to be
  # spliced back in explicitly or `password`/`passwd`/`secret` would stop being
  # scrubbed. `Sentry.Scrubber.scrub/2` walks nested maps and lists for us and
  # matches atom keys as well as string ones, so `%{event: ..., params: %{...}}`
  # (the `handle_event` breadcrumb shape) is handled at any depth.
  @app_sensitive_keys ["nombre", "value"]

  @doc """
  Scrubs a `Sentry.LiveViewHook` breadcrumb `data` map.

  Wired as `on_mount {Sentry.LiveViewHook, scrubber: {__MODULE__, :scrub, []}}`
  in `PukllayClubWeb.live_view/0`, so it applies to every LiveView in the app.
  """
  @spec scrub(map()) :: map()
  def scrub(data) when is_map(data) do
    Sentry.Scrubber.scrub(data, keys: Sentry.Scrubber.default_param_keys() ++ @app_sensitive_keys)
  end
end
