# Connection Feedback

**Status: not yet built.** This is a distinct surface from `empty-loading-error-states.md` — that
file covers catalog/detail *query*-level states (empty results, a scoped load error). This one
covers a genuine **websocket transport disconnect** — the whole LiveView connection drops (real
offline, a server restart), a categorically different failure mode Phoenix LiveView's own JS client
detects and handles independently of any app-level query.

## Design Decisions

**Replace the stock `phx.new` connection banner — never restyle it in place.** UAT caught this
verbatim, untouched scaffolding in production: `flash_group/1`'s `#client-error`/`#server-error`
elements render as a stock daisyUI `toast-top toast-end` overlay, with no `pk-*` class anywhere on
them (unlike every other surface in the app), and in un-translated English ("Something went wrong!"
/ "Attempting to reconnect" / "We can't find the internet") even though the rest of the app is
Spanish. Both defects — unbranded chrome and un-localized copy — trace to the same root cause:
this component was never touched since generator scaffolding.

**Inline bar under the header won over a restyled corner toast or a retry-line-style pill.** Three
placements were sketched: a full-width bar directly under the header (on-brand tokens, pushes
content down), a reskinned version of the existing corner-toast pattern (title+body split, softer
shadow/border), and a compact pill matching the app's existing scoped `:more_error` inline
"Reintentar" retry-line so both failure modes would read as one visual family. **The inline bar
won** — always in the same predictable place, doesn't float over content the way a toast does.

**Color: the app's own accent tint, not `--color-danger`.** The first pass reused the danger-red
token for the icon/spinner — an instinctive "this is an error state" choice that read as alarming
for what is, in the overwhelming majority of cases, a brief, automatically-recovering reconnect.
Recolored to the app's accent tint (informative, not alarming) and centered the message for a
calmer, more deliberate announcement instead of a left-pinned strip.

```css
.pk-conn-banner { display: none; align-items: center; justify-content: center; gap: 10px; background: var(--color-accent-bg); color: var(--color-accent-text); border-bottom: 1px solid var(--color-border); padding: 11px var(--space-4); font-size: var(--text-sm); font-weight: 600; text-align: center; }
body.phx-client-error .pk-conn-banner,
body.phx-server-error .pk-conn-banner { display: flex; }

.pk-conn-banner .spinner { width: 14px; height: 14px; border: 2px solid currentColor; border-right-color: transparent; border-radius: 50%; animation: pk-spin 0.7s linear infinite; }
@keyframes pk-spin { to { transform: rotate(360deg); } }
```

**Copy: Spanish, informative, not alarmed.** "Reconectando… no encontramos tu conexión a internet"
— replaces both the `#client-error`/`#server-error` gettext strings with one combined message; the
distinction between "can't find your connection" and "something went wrong, reconnecting" wasn't
meaningfully different to a visitor and collapsing them into one line is simpler than adding a
Spanish gettext catalog for two separate messages that say almost the same thing.

## HTML/Wiring Pattern

Same `phx-disconnected`/`phx-connected` class-toggling mechanism LiveView already drives — this is
a markup/CSS replacement for `flash_group/1`'s `#client-error`/`#server-error` divs, not a new JS
mechanism:

```heex
<div class="pk-conn-banner" id="client-error" phx-disconnected={show(".pk-conn-banner")} phx-connected={hide(".pk-conn-banner")} hidden>
  <span class="spinner"></span>
  <span>Reconectando… no encontramos tu conexión a internet</span>
</div>
```

## What to Avoid

- Don't restyle the stock `#client-error`/`#server-error` toast in place — replace its markup with
  an on-brand `pk-*` component; the toast placement itself was part of what read as "weird floating
  card," not just the missing styling.
- Don't reuse `--color-danger` for a transient, usually self-recovering reconnect state — it reads
  as alarming for a low-stakes moment. Use the accent tint.
- Don't leave this surface in English — it's the one place in the app that still ships raw
  generator-default copy.
- Don't conflate this with the existing scoped `:more_error` inline retry-line
  (`CatalogLive.Index`'s load-more failure handling) — that one only fires on a live, connected
  query failure; this one only fires on an actual transport disconnect. They're different
  mechanisms even if visually related.

## Origin
Synthesized from sketch: 030
Source file available in: sources/030-connection-lost-banner/
Real implementation target: `lib/pukllay_club_web/components/layouts.ex` (`flash_group/1`)
