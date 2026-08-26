---
sketch: 030
name: connection-lost-banner
question: "What should the offline/connection-lost banner look like, on-brand and in Spanish?"
winner: "A"
tags: [feedback, offline, banner, connection, gap-closure]
---

# Sketch 030: Connection Lost Banner

## Design Question
UAT gap G-01.2-8: "There is a weird floating card at the top — 'Something went wrong! Attempting
to reconnect' — This must to follow our visual identity." Root-cause diagnosis
(`.planning/debug/G-01.2-8-offline-retry-banner.md`) confirmed the app's `flash_group/1` connection
banner (`#client-error`/`#server-error`) is verbatim, untouched `phx.new` scaffolding: a stock
daisyUI `toast-top toast-end` overlay, unstyled with any `pk-*` class, and in un-translated English
even though every other string in the app is Spanish. This sketch explores a branded, Spanish
replacement — the surface that renders on a genuine websocket transport disconnect (distinct from
the existing scoped `:more_error` inline retry-line, which only handles a live query-level failure).

## How to View
open .planning/sketches/030-connection-lost-banner/index.html

Click "Simular desconexión" to preview the disconnected state.

## Winner: A — Inline Bar (Round 3 recolored)
Full-width bar directly under the header, on-brand tokens, centered message.

## Round history
- **Round 1** — three placements explored: **A Inline Bar** (full-width, under the header), **B
  Restyled Toast** (kept the existing corner-toast pattern, reskinned with brand tokens), **C
  Retry-line Family** (matches the existing compact "Reintentar" pill so both failure modes look
  related).
- **Round 2** — feedback: the fixed toolbar's caption text was wrapping onto a second row on
  common widths, growing the toolbar past its own reserved space and covering the banner
  underneath (a `position: fixed` element draws over in-flow content in the same screen space
  regardless of source order). Fixed: caption now truncates with an ellipsis instead of wrapping,
  toolbar never grows past one row.
- **Round 3** — A picked, but "not red, something better" for balance/tone. The banner had reused
  `--color-danger` for its spinner/icon (a leftover instinct from styling an "error" state) — red
  reads as alarming for what's usually a brief, self-recovering reconnect. Recolored to the app's
  own accent tint (informative, not alarming) and centered the message for a calmer, more
  deliberate announcement instead of a left-pinned strip. B/C removed from `index.html` (A only).

## What to Look For
- Does it read as "this app is handling a brief interruption," not an error or a crash?
- Is the Spanish copy clear about what's happening without being alarming?
- Does it stay legible/on-brand in both light and dark themes?
