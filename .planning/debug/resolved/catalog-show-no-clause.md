---
status: resolved
trigger: "https://pukllay-club.sentry.io/issues/7726971875/events/fcba376e2f4b49179771e62c99f16563/"
created: 2026-09-12
updated: 2026-09-12
---

# Debug: FunctionClauseError in CatalogLive.Show.handle_event/3

## Symptoms

**Source:** Sentry issue `ELIXIR-1` (org `pukllay-club`, project `elixir`), event
`fcba376e2f4b49179771e62c99f16563`.

**Expected behavior:** Every event the `/juegos/:slug` detail page (`CatalogLive.Show`)
can dispatch from its template has a matching `handle_event/3` clause, so no user
interaction crashes the LiveView process.

**Actual behavior:** A LiveView client event reached
`PukllayClubWeb.CatalogLive.Show.handle_event/3` with no matching clause, raising
`FunctionClauseError` and crashing the LiveView channel process (the user's page
would have reconnected/remounted, losing in-page state such as an open lightbox or
reservation modal).

**Error message:**
```
FunctionClauseError: no function clause matching in
PukllayClubWeb.CatalogLive.Show.handle_event/3
```

**Stacktrace (first-party frame last):**
```
:proc_lib.init_p_do_apply/3 (proc_lib.erl:333)
:gen_server.handle_msg/3 (gen_server.erl:2420)
:gen_server.try_handle_info/3 (gen_server.erl:2434)
Phoenix.LiveView.Channel.handle_info/2 (lib/phoenix_live_view/channel.ex:265)
:telemetry.span/3 (deps/telemetry/src/telemetry.erl:359)
anonymous fn/3 in Phoenix.LiveView.Channel.view_handle_event/3 (channel.ex:565)
PukllayClubWeb.CatalogLive.Show.handle_event/3 (lib/pukllay_club_web/live/catalog_live/show.ex:140)
```

Note: `show.ex:140` is the FIRST `handle_event/3` clause in the module
(`"open-search"`), which is what Elixir reports for a whole-function clause
mismatch — it is NOT necessarily the clause at fault. The actual failing event
name and params were NOT captured in the Sentry payload (`domain` is
`["[Filtered]"]`, and no `event`/`params` extra was attached).

**Timeline:** First and last seen 2026-09-11T18:31:03Z. 1 occurrence, 0 users
impacted (anonymous). Environment `prod`, server `34.41.63.138` (the GCP e2-micro),
Elixir 1.19.5 / OTP 28. Client geo: Council Bluffs, US — a US datacenter region,
consistent with a bot/crawler or a synthetic probe rather than a club member in
Jujuy, but that is a hypothesis to test, not an established fact.

**Reproduction:** Unknown — not reproduced locally yet. Reproduction requires
identifying which `phx-click`/`phx-change`/`phx-submit`/`phx-keydown` (or JS-pushed)
event name the detail page's template (and any shared layout/component rendered
inside it, e.g. `header_inner/1`, the lightbox, the reservation modal) can emit
that has no matching clause in `CatalogLive.Show`.

## Current Focus

bug_class: Bohrbug — fully deterministic, reproduces 100% of the time on a
single blur of the reservation name input. (SBFL skipped: no per-test coverage
tooling wired, and no failing test existed before this session.)

reasoning_checkpoint:
  hypothesis: "`phx-blur=\"validate-reservation\"` sits on the `<input
    name=\"nombre\">` inside the reservation modal. A `phx-blur` is NOT a form
    event — nothing serializes the form — so the input's `name` never reaches
    the params. LiveView's client builds the payload with `extractMeta`, which
    emits every `phx-value-*` attribute plus, for any element with a native
    `.value`, that value under the key `\"value\"`. The browser therefore sends
    `%{\"value\" => \"<typed name>\"}`, while the handler pattern-matches
    `%{\"nombre\" => name}` — no clause matches, so Elixir raises
    FunctionClauseError and reports the module's FIRST handle_event clause
    (show.ex:140, \"open-search\")."
  confirming_evidence:
    - "Direct read of the shipped client, deps/phoenix_live_view/priv/static/
       phoenix_live_view.esm.js:5856-5864: `if (el.value !== void 0 && !(el
       instanceof HTMLFormElement)) { meta.value = el.value }`."
    - "Same file:7217-7225 — the focusout/focusin binding pushes
       `{...this.eventMeta(type, e, targetEl)}`, and eventMeta (7299-7302)
       returns `{}` when no metadata callback is registered. assets/js/app.js
       registers none, so the blur payload is exactly extractMeta's output."
    - "Same file:5947-5959 — `pushEvent` sets `value: this.extractMeta(el, meta,
       opts.value)`, confirming the blur push runs extractMeta."
    - "Executed reproduction (throwaway test, since deleted): opening the
       reservation modal then pushing a blur with the browser-shaped payload
       raised FunctionClauseError with a stacktrace matching the Sentry event
       FRAME FOR FRAME — show.ex:140 -> channel.ex:565 -> telemetry.erl:359 ->
       channel.ex:265 -> gen_server.erl:2434 -> gen_server.erl:2420 ->
       proc_lib.erl:333."
    - "The LiveView envelope in that run was `%{\"event\" =>
       \"validate-reservation\", \"type\" => \"blur\", \"value\" => %{\"value\" =>
       \"Ana\"}}` — the transport confirms the params shape independently."
    - "A CONTROL case in the same run (`%{\"nombre\" => \"Ana\"}`) passed,
       isolating the params SHAPE as the variable rather than the event name,
       the modal state, or the handler body."
  falsification_test: "If the blur payload carried the form's `nombre` key, the
    browser-shaped `%{\"value\" => ...}` push would have been a straw man and the
    CONTROL/variant pair would both have passed. Both the framework source and
    the executed run refute that."
  fix_rationale: "The handler's pattern is the half that is wrong: the client's
    payload shape is fixed by the framework and cannot be changed from the
    template without abandoning `phx-blur` entirely. Matching `%{\"value\" =>
    name}` makes the server half agree with the contract the browser actually
    speaks, so the root cause (a pattern/payload disagreement) is removed
    rather than masked. `reserve` is deliberately left matching `%{\"nombre\"
    => name}` — it is a real `phx-submit` on the <form>, so it genuinely does
    receive serialized form params."
  blind_spots: "CLOSED (2026-09-12, human-verify checkpoint): the real-browser
    blind spot no longer applies — a Chrome session against a dev server logged
    `HANDLE EVENT \"validate-reservation\" ... Parameters: %{\"value\" =>
    \"Ana\"}`, so the payload shape is now a RECORDED observation from a real
    client, not an inference from the shipped source. REMAINING: the Sentry
    event's own params were never captured, so the match to THAT specific event
    still rests on the stacktrace being frame-identical and on this being the
    only reachable unhandled payload on the page. The client geo (Council
    Bluffs, US) remains unexplained by this root cause."
  candidate_causes:
    - "code: phx-blur payload shape vs handler pattern mismatch — CONFIRMED."
    - "code (latent, second instance of the same class): `carousel-load-more`
       is pushed by CarouselRow's .CarouselScroll hook and has NO clause in
       Show. Currently unreachable because Show passes `exhausted={true}` and
       the hook early-returns on it — so NOT the cause of this event (its
       payload would have been %{\"row\" => \"similares\"}), but one attribute
       away from crashing."
    - "config: ELIMINATED — assets/js/app.js registers no liveSocket
       `metadata` callbacks, so nothing re-shapes the blur payload."
    - "environment: ELIMINATED — reproduces deterministically in the local
       test env; not prod-specific."
    - "data: ELIMINATED — no game record participates in the failing payload."
  and_gate: "no — a single blur on #reservation-nombre is sufficient and
    deterministic. Opening the modal and a configured reservation number are
    preconditions of reaching the input at all, not independent co-causes."

next_action: none — human verification passed in a real browser
(2026-09-12), fix committed on `fix/catalog-show-reservation-blur-payload`,
session archived.

## Evidence

- timestamp: 2026-09-11T18:31:03Z
  observation: Sentry event fcba376e2f4b49179771e62c99f16563 — FunctionClauseError
  in CatalogLive.Show.handle_event/3, prod, 1 occurrence, unhandled, crashed the
  LiveView channel process.

- checked: Enumerated every client event reachable from the rendered detail page
  (own template, Layouts.app/header_inner, CarouselRow, GameChips, GamePreview,
  GameCard, CoreComponents, FilterModal) via grep for phx-click/change/submit/
  keydown/blur/focus/viewport bindings, JS.push, and colocated-hook pushEvent.
  found: The reachable set is {open-search, close-search, select-image,
  select-lightbox-image, toggle-description, open-lightbox, close-lightbox,
  open-reservation, close-reservation, validate-reservation, reserve,
  carousel-load-more}. `lv:clear-flash` is handled internally by LiveView and
  never reaches handle_event/3. FilterModal is NOT rendered on this page.
  implication: Only `carousel-load-more` has no clause by NAME — but every
  clause with a restrictive params pattern is an equally valid crash site,
  which reframed the search from missing NAMES to mismatched PAYLOADS.

- checked: show.ex:1011 — `phx-blur="validate-reservation"` is set on the
  `<.input name="nombre">` (forwarded to the <input> through the component's
  `:rest` global), and show.ex:229 matches `%{"nombre" => name}`.
  found: A blur is not a form event; LiveView sends the element's own `.value`
  under the key "value" (extractMeta, esm.js:5856-5864) and nothing else here,
  since the input carries no `phx-value-*` attributes.
  implication: The handler can never match. Every blur of that input crashes
  the LiveView — this is the exact inverse of the trap already documented at
  filter_modal.ex:87, where `"value"` CLOBBERED an intended binding; here
  `"value"` is the only key that arrives.

- checked: Ran a throwaway 3-case experiment (browser-shaped payload /
  element-based blur / control with the documented shape).
  found: The two browser-shaped cases raised FunctionClauseError with a
  stacktrace frame-identical to the Sentry event (show.ex:140 first);
  the control passed. Transport envelope: `%{"event" => "validate-reservation",
  "type" => "blur", "value" => %{"value" => "Ana"}}`.
  implication: Root cause confirmed by direct observation, not inference.

- checked: `grep -rn 'validate-reservation|render_blur|"reserve"' test/`
  found: Zero hits — no test in the suite drives either reservation handler.
  implication: The reservation flow's server half was entirely untested, which
  is why a green suite coexisted with a 100%-reproducible prod crash.

- checked: Every other phx-blur/phx-focus/phx-keydown binding in lib/.
  found: show.ex:1011 is the ONLY one in the whole application.
  implication: No sibling instances of this exact sub-class to fix.

- checked: Show's CarouselRow.carousel_row call site (show.ex:755) against the
  .CarouselScroll hook's maybeLoadMore (carousel_row.ex:180-195).
  found: Show passes `exhausted={true}` -> `data-exhausted="true"`, and the
  hook early-returns `if (this.pending || this.exhausted)`.
  implication: `carousel-load-more` is client-guarded today, so it is NOT this
  Sentry event — but the guard is a single template attribute, and the server
  has no clause behind it. Closing it costs 4 lines and is semantically
  correct (the shelf genuinely IS exhausted), so it is fixed alongside.

- checked: HUMAN-VERIFY CHECKPOINT (2026-09-12) — a real Chrome browser driven
  against a local dev server (`MIX_ENV=dev mix phx.server`, game `/juegos/10`
  "Cooper Island"), watching both the browser console and the dev server log.
  found: All four verification steps passed. (1) The reservation modal opens
  from the detail-page CTA. (2) Typing "Ana" and clicking the submit button
  renders the WhatsApp block, with the modal preserved — no reconnect flicker,
  no remount. (3) Focusing the input and tabbing out WITHOUT typing renders the
  empty-name message instead of crashing. (4) Scrolling "Juegos similares" to
  its true end (last item: Brass: Birmingham) produces no crash and no repeated
  network chatter. Browser console: zero errors. Dev server log: zero
  FunctionClauseError, zero `[error]` lines, zero GenServer terminations. The
  dev server logged the payload DIRECTLY:
      [debug] HANDLE EVENT "validate-reservation" in PukllayClubWeb.CatalogLive.Show
        Parameters: %{"value" => "Ana"}   -> Replied in 185µs
        Parameters: %{"value" => ""}      -> Replied in 155µs
  implication: The live client sends `%{"value" => ...}` exactly as the
  root-cause analysis predicted from reading phoenix_live_view.esm.js:5856.
  This converts the payload shape from a DERIVED oracle (read off the shipped
  client source) into a RECORDED one, and closes the session's only
  fix-blocking blind spot. It also independently confirms the
  `carousel-load-more` clause: the shelf was scrolled to its end with no crash.

- checked: Observed click behaviour of the modal's submit button in the same
  browser session.
  found: Clicking the submit button BLURS the focused name input first, so the
  `phx-blur` fires ahead of the `phx-submit` on every pointer-driven submit.
  implication: Severity is materially worse than the Sentry event's "1
  occurrence, 0 users impacted" suggests. The crash was not a rare
  tab-out-without-typing edge case — it fired on the ordinary happy path for
  every pointer (mouse/touch) user who filled the field and clicked. The
  reservation flow was effectively broken in prod for pointer users; the
  handler never even reached `reserve`, because the LiveView process died
  during the blur that preceded it. The low Sentry count reflects low traffic
  on a just-launched page plus Sentry's own issue grouping, not low blast
  radius.

## Eliminated

- hypothesis: The crash came from the `"open-search"` clause named at
  show.ex:140 in the stacktrace.
  evidence: Elixir reports a whole-function clause mismatch at the FIRST
  clause of the function. The reproduction raised at the identical line while
  the actual event was `validate-reservation`.
  timestamp: 2026-09-12

- hypothesis: A later-added shared component re-introduced a missing event
  NAME, the way open-search/close-search once were.
  evidence: Full enumeration of the reachable event set found only
  `carousel-load-more` missing by name, and it is unreachable from this page
  because `exhausted={true}` makes the hook early-return before pushing. The
  real gap was a mismatched PAYLOAD on an event whose name was handled.
  timestamp: 2026-09-12

- hypothesis: A liveSocket `metadata` callback re-shapes the blur payload.
  evidence: assets/js/app.js registers no `metadata` option, and
  `eventMeta/3` (esm.js:7299-7302) returns `{}` without one.
  timestamp: 2026-09-12

- hypothesis: Environment-specific (prod-only) behaviour.
  evidence: Reproduces deterministically in the local :test environment.
  timestamp: 2026-09-12

## Resolution

root_cause: `phx-blur="validate-reservation"` on the reservation modal's name
input (show.ex:1011) makes LiveView's client send `%{"value" => "<typed
name>"}` — a blur is not a form event, so the input's `name="nombre"` is never
serialized, and `extractMeta` supplies only the element's native `.value`
under the key `"value"`. The handler (show.ex:229) pattern-matched
`%{"nombre" => name}`, so no clause matched and `handle_event/3` raised
FunctionClauseError, reported against its first clause at show.ex:140.

  SEVERITY (confirmed in-browser at the human-verify checkpoint): clicking the
  modal's submit button blurs the focused input FIRST, so the crash fired ahead
  of every pointer-driven submit — not only on the tab-out-without-typing path.
  For mouse and touch users the reservation flow was effectively broken in
  prod: the LiveView process died during the blur and `reserve` was never
  reached. The Sentry event's "1 occurrence / 0 users impacted" understates the
  blast radius; it reflects low traffic on a freshly launched page, not a rare
  trigger.
fix: Two changes in `lib/pukllay_club_web/live/catalog_live/show.ex`.
  (1) ROOT CAUSE — `handle_event("validate-reservation", ...)` now matches
  `%{"value" => name}`, the payload LiveView's client actually builds for a
  `phx-blur` on an <input>, instead of `%{"nombre" => name}` (which only a
  real form submit produces). `reserve` deliberately keeps `%{"nombre" =>
  name}` — it IS a phx-submit on the <form>. A why-comment at the clause
  records the extractMeta mechanism, cross-references filter_modal.ex's
  mirror-image trap, and states explicitly that `mix test` cannot catch a
  revert from markup alone.
  (2) LATENT GAP (same class, not this Sentry event) — added
  `handle_event("carousel-load-more", _params, socket)` replying
  `%{exhausted: true}`. CarouselRow's .CarouselScroll hook can push this from
  any page with a shelf; Show had no clause, protected only by the
  `exhausted={true}` template attribute. The reply is the truthful answer
  (the shelf has no paging) and is the stop signal the hook latches on.

verification: |
  guardrail_verdict: accepted

  signal_1_reverted_fix_reproduces_bug: PASS — reverting the params pattern to
    `%{"nombre" => name}` turns 5 of the new tests red with the original
    FunctionClauseError. The bug returns on revert, so the fix is what removed
    it.

  signal_2_mutation_at_fix_site: PASS — 6 mutants, all killed:
    (1) revert validate-reservation pattern -> 5 failures
    (2) `{:reply, %{exhausted: true}, socket}` -> `{:noreply, socket}` -> 1
    (3) delete the carousel-load-more clause -> 2
    (4) off-by-one on the 60-grapheme boundary (>60 -> >61) -> 2
    (5) add `phx-value-nombre` to the blurring input -> 2
    (6) drop `phx-blur` from the input entirely -> 2
    No surviving mutant at the fix site.

  signal_3_regression_tests_added: PASS — 12 new tests in
    `test/pukllay_club_web/live/catalog_show_test.exs`:
    - 5 payload-shape tests driving the real browser blur payload, including
      boundary neighbours at 0, whitespace-only, exactly 60, and 61 graphemes.
    - a markup-contract test pinning that the blurring input carries no
      `phx-value-*` attribute, so "value" really is the only key that arrives.
    - an asymmetry pin proving `reserve` still speaks form params.
    - a class-guard test that re-derives the page's dispatchable event set
      (rendered-markup attribute scan UNION colocated-hook `pushEvent` source
      scan) and asserts it equals a reviewed 12-name list — this automates the
      exact enumeration that diagnosed the bug, and it is what fails if a
      future shared component introduces a new unhandled event name.
    - carousel-load-more behaviour + reply-contract tests.
    Oracle type: DERIVED — the expected payload is read off the shipped client
    source, not guessed.

  signal_4_diff_is_not_deletion_only: PASS — the diff adds a clause and
    corrects a pattern; nothing was removed to make a test pass.

  signal_5_project_gate: PASS — `mix quality` exits 0 (hex.audit, deps.audit,
    deps.unlock --check-unused, format --check-formatted with Styler, credo
    --strict, sobelow, test). Full suite 1028 tests, 0 failures. The one
    Styler rewrite touching pre-existing code was a pure alias substitution
    (`PukllayClubWeb.CatalogLive.Show` -> `Show`), reviewed per Styler's own
    "review every rewrite" guidance.

  signal_6_human_verification: PASS (2026-09-12) — real Chrome browser against a
    dev server. All four steps green (modal opens; typed name renders the
    WhatsApp block with the modal preserved; tab-out-without-typing shows the
    empty-name message instead of crashing; the similar-games shelf scrolls to
    its true end). Zero browser-console errors, zero server-side
    FunctionClauseError / `[error]` lines / GenServer terminations. The dev
    server log recorded `Parameters: %{"value" => "Ana"}` and
    `Parameters: %{"value" => ""}` for `validate-reservation`, upgrading the
    payload-shape oracle from DERIVED to RECORDED.

  No remaining NOT-verified items block this fix.

files_changed:
  # Commit 1 — the root-cause fix (Fixes ELIXIR-1)
  - lib/pukllay_club_web/live/catalog_live/show.ex
  - test/pukllay_club_web/live/catalog_show_test.exs
  # Commit 2 — observability follow-up approved at the human-verify checkpoint
  - lib/pukllay_club_web.ex
  - lib/pukllay_club_web/sentry_scrubber.ex
  - test/pukllay_club_web/sentry_scrubber_test.exs
  # Commit 3 — reservation copy rewrite (separate user request, same PR)
  - lib/pukllay_club_web/live/catalog_live/show.ex
  - test/pukllay_club_web/live/catalog_show_test.exs

follow_ups_landed_in_the_same_PR:
  - "Sentry.LiveViewHook attached in PukllayClubWeb.live_view/0 with a custom
     scrubber (PukllayClubWeb.SentryScrubber). This exists because ELIXIR-1's
     payload contained NEITHER the event name NOR the params, which is what
     made a 10-line bug take a full event-set enumeration to find. Policy is
     keep-the-keys/drop-the-values: the event name and param KEYS are the
     entire diagnostic payload for a clause mismatch, while the typed value
     has no diagnostic value and is user data. Sentry's default scrubber only
     catches credential-shaped keys (password/passwd/secret), so `nombre` and
     `value` would otherwise have reached a third party."
  - "Reservation copy rewritten into a terser register (a separate user
     request raised at the same checkpoint, not part of the bug). Voseo and
     the D-09/D-10 framing are unchanged. One item — reservation_message/2 —
     is applied but flagged in the PR as not user-approved."

decisions_declined:
  - "A catch-all `handle_event/3` clause was considered and REJECTED. It would
     convert this crash class into a silent no-op, which is strictly worse:
     the LiveView would stop crashing while the feature stayed broken, and
     nothing would ever report it. The class guard test (which re-derives the
     page's dispatchable event set and asserts it against a reviewed list) is
     the chosen guard instead — it fails loudly at build time rather than
     swallowing the failure at runtime."
