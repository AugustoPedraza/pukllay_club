// AdminList — the Juegos screen's own interaction layer (plan 01.8.2-14,
// D-19g-bis/D-19n; pinned row rebuilt by plan 01.8.3-01, D-06/D-07/D-09;
// pin-observer/sticky-offset fix by plan 01.8.3-03, D-15; the pinned
// caption's sticky offset made DYNAMIC by plan 01.8.3-11, D-20a — see
// `mounted()`'s `applyEffectivePinnedPx`/`scheduleGrowth` for the fix and
// the "measured fact" comment there for the defect this closes
// (G-01.8.3-2d/G-01.8.3-3, T-01.8.3-34/35/36)).
// Registered as a plain (non-colocated) hook in `app.js`'s `hooks` object
// (`phx-hook="AdminList"`, no leading dot), mirroring `AdminRail`'s own
// non-colocated convention: mounted once on the page's stable wrapper
// (`#juegos-page`) rather than on any conditionally-rendered child, since
// sections/rows come and go as groups collapse/expand and as the search
// narrows the list.
//
// Three independent jobs (the page bar/back-row toggling this hook used
// to own is gone — D-06/D-09 deleted both from this page's DOM):
//   1. Expand-keeps-position (D-19g-bis decision 8/18): opening or
//      closing a collapsible section keeps the TAPPED heading exactly
//      where the finger left it — captured on click, corrected after the
//      LiveView diff lands.
//   2. Pinned section captions (D-19n): an IntersectionObserver watches a
//      zero-height sentinel placed just before each section's sticky
//      heading and toggles `data-pinned` on the heading wrap the instant
//      the sentinel scrolls above the pinned search row — the heading
//      gains its `::before` band fill (juegos.css) ONLY while pinned. The
//      pin predicate is `!entry.isIntersecting` alone: 01.8.3-RESEARCH.md
//      found the prior real-viewport rect comparison (a second, stricter
//      AND-clause) dominated a correctly-sized `rootMargin` and re-opened
//      the ~45px window the `rootMargin` already compensated for — an
//      IntersectionObserverEntry's real-viewport rect is never affected
//      by `rootMargin`, so ANDing a check against it back in always fires
//      later than the `rootMargin`'s own compensation (D-15).
//   3. D-08's pinned search row: the SAME `#juegos-search-wrap` (never a
//      second, synced copy) hides on scroll-down and returns on
//      scroll-up, never while `#juegos-search-input` is focused and never
//      within 140px of the top — ported verbatim from
//      `assets/js/hooks/admin_rail.js`'s own D-19n mechanism (D-18:
//      per-screen-owns-its-hook, a copy, not a shared import).
//
// Plus one unrelated job kept from before: scroll a freshly-created
// draft's row into view once (D-37 gate 4, 076's `.fresh` pattern) — the
// row's own `.pk-admin-juegos-row--fresh` class marks it.
//
// Purely client-driven presentational toggling (pinned-row hide/return,
// pinned-caption fill) — same shape as `AdminRail`'s `data-pinned-hidden`
// — rather than a LiveView assign updated on every scroll tick, so
// scrolling never costs a server round trip.

export default {
  mounted() {
    this.pendingToggle = null
    this.lastFreshId = null

    this.onClick = (e) => {
      const toggle = e.target.closest("[data-pk-section-toggle]")
      if (toggle && this.el.contains(toggle)) {
        this.pendingToggle = { id: toggle.id, top: toggle.getBoundingClientRect().top }
      }
    }
    this.el.addEventListener("click", this.onClick)

    // D-08: the pinned search row — ported verbatim from
    // `admin_rail.js`'s D-19n mechanism, Juegos-scoped ids.
    this.searchWrap = this.el.querySelector("#juegos-search-wrap")
    this.searchInput = this.el.querySelector("#juegos-search-input")
    this.lastScrollY = window.scrollY

    // D-15: the pin-observer's rootMargin must track the REAL pinned
    // search row's rendered height, not a literal — measured once here
    // from the same wrap juegos.css's own `--pk-juegos-pinned-h` declares
    // the section captions' sticky offset from. If the wrap cannot be
    // measured (absent, or its height rounds to 0), fall back to a single
    // declared default rather than to 0 — a 0 inset would silently
    // re-open the window this fix closes. 60 is `4 + 48 + 8`: the row's
    // own top padding, the 48px field (D-07), and its bottom padding
    // (`.pk-admin-juegos-search-row` in juegos.css) — traceable to the
    // stylesheet, not arbitrary.
    const measuredHeight = this.searchWrap
      ? Math.round(this.searchWrap.getBoundingClientRect().height)
      : 0
    this.pinnedBandPx = measuredHeight > 0 ? measuredHeight : 60

    // Plan 01.8.3-11 [T-01.8.3-34, G-01.8.3-2d/G-01.8.3-3, D-20a]: the
    // EFFECTIVE reservation — either 0 (row hidden) or `this.pinnedBandPx`
    // (row visible or returning) — kept separate from `pinnedBandPx` above,
    // which is the row's own measured full height and never changes once
    // measured. Measured fact this fix closes: `--pk-juegos-pinned-h` was
    // declared once (juegos.css), READ TWICE (this observer's own
    // rootMargin/threshold below) and WRITTEN NEVER — on scroll-down the
    // caption's sticky offset stayed at the row's full height while the row
    // itself translated fully off-screen, stranding the band 60px below
    // the viewport top with live list rows scrolling through the gap. This
    // value is written to the custom property in LOCKSTEP with the hide
    // attribute — never independently — so the two can never drift apart
    // again, and the observer below is rebuilt from this SAME value so the
    // pin trigger and the sticky offset can never disagree about where
    // pinned begins (the exact class of bug `setupPinObserver()`'s own
    // comment already records from plan 01.8.3-03).
    this.effectivePinnedPx = this.pinnedBandPx
    this.growthTimer = null
    this.growthListener = null

    this.applyEffectivePinnedPx = (value) => {
      if (value === this.effectivePinnedPx) return
      this.effectivePinnedPx = value
      this.el.style.setProperty("--pk-juegos-pinned-h", `${value}px`)
      // The observer is REBUILT, not re-configured — `rootMargin` is
      // immutable after construction, so the only way to keep it agreeing
      // with a changing reservation is to construct a fresh observer. Only
      // when the effective value actually changed (this branch), never on
      // every scroll tick.
      this.setupPinObserver()
    }

    this.cancelPendingGrowth = () => {
      if (this.growthTimer) {
        clearTimeout(this.growthTimer)
        this.growthTimer = null
      }
      if (this.growthListener && this.searchWrap) {
        this.searchWrap.removeEventListener("transitionend", this.growthListener)
        this.growthListener = null
      }
    }

    // Plan 01.8.3-11: the HIDE + SHRINK (onScroll below) happen in the same
    // tick — the row is mid-transition, occupying the top of the viewport,
    // and `.pk-admin-juegos-search-wrap`'s `z-index: 15` paints above the
    // heading wrap's `z-index: 10` (juegos.css), so the band — already in
    // its final (0) position — is revealed progressively from BEHIND the
    // outgoing row. Nothing moves twice. The GROWTH back to full height is
    // deferred to here: either the wrap's own `transform` transition
    // ending, or a fallback timer derived from the wrap's own computed
    // `transition-duration` at the moment this runs (never a copied token
    // value), applied immediately when that duration resolves to zero — a
    // reduced-motion or transition-less environment must not strand the
    // reservation at 0. Growing it at the START of the return would move
    // the band down while the row is still sliding in, reopening a
    // transient version of the same window this whole mechanism closes;
    // waiting means the band descends onto a row that has already arrived.
    this.scheduleGrowth = () => {
      this.cancelPendingGrowth()
      if (!this.searchWrap) {
        this.applyEffectivePinnedPx(this.pinnedBandPx)
        return
      }
      const durationRaw = getComputedStyle(this.searchWrap).transitionDuration.split(",")[0].trim()
      const durationValue = parseFloat(durationRaw)
      const durationMs = Number.isNaN(durationValue) ? 0 : durationValue * (durationRaw.endsWith("ms") ? 1 : 1000)
      if (!durationMs) {
        this.applyEffectivePinnedPx(this.pinnedBandPx)
        return
      }
      this.growthListener = (e) => {
        if (e.propertyName !== "transform") return
        this.cancelPendingGrowth()
        this.applyEffectivePinnedPx(this.pinnedBandPx)
      }
      this.searchWrap.addEventListener("transitionend", this.growthListener)
      // Fallback: covers a transitionend that never fires (interrupted
      // transition, a browser quirk) — whichever fires first wins, and
      // cancelPendingGrowth() inside each path removes the other.
      this.growthTimer = setTimeout(() => {
        this.cancelPendingGrowth()
        this.applyEffectivePinnedPx(this.pinnedBandPx)
      }, durationMs + 50)
    }

    this.onScroll = () => {
      if (!this.searchWrap) return

      const y = window.scrollY
      const goingDown = y > this.lastScrollY
      this.lastScrollY = y

      const focused = document.activeElement === this.searchInput
      // Never within 140px of the top, regardless of scroll direction —
      // a new screen always starts at scrollTop 0, so the pinned state
      // never appears on a page nobody scrolled.
      const nearTop = y <= 140
      // Plan 01.8.3-11: read BEFORE mutating the attribute below — this is
      // what lets un-hide branches schedule growth exactly once (on the
      // hidden->visible edge), not on every scroll tick while already
      // visible. One place decides both the hidden attribute AND the
      // effective value together, so the two can never be set from
      // different branches.
      const wasHidden = this.searchWrap.hasAttribute("data-pinned-hidden")

      if (focused || nearTop) {
        this.searchWrap.removeAttribute("data-pinned-hidden")
        if (wasHidden) this.scheduleGrowth()
      } else if (goingDown) {
        // A second direction change before a pending growth fires cancels
        // it — the reservation must never grow back while the row is
        // hidden again.
        this.cancelPendingGrowth()
        this.searchWrap.setAttribute("data-pinned-hidden", "true")
        this.applyEffectivePinnedPx(0)
      } else {
        this.searchWrap.removeAttribute("data-pinned-hidden")
        if (wasHidden) this.scheduleGrowth()
      }
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })

    this.setupPinObserver()
    this.scrollFreshIntoView()
  },

  updated() {
    if (this.pendingToggle) {
      const { id, top } = this.pendingToggle
      this.pendingToggle = null
      const el = document.getElementById(id)
      if (el) {
        const delta = el.getBoundingClientRect().top - top
        if (delta !== 0) window.scrollBy(0, delta)
      }
    }
    this.setupPinObserver()
    this.onScroll?.()
    this.scrollFreshIntoView()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    window.removeEventListener("scroll", this.onScroll)
    this.pinObserver?.disconnect()
    // Plan 01.8.3-11: cancel any pending growth AND remove the listener it
    // added — a `transitionend` handler left on a detached-but-not-yet-
    // garbage-collected wrap would fire into a hook that no longer exists.
    this.cancelPendingGrowth?.()
  },

  setupPinObserver() {
    this.pinObserver?.disconnect()
    const sentinels = [...this.el.querySelectorAll("[data-pk-section-sentinel]")]
    if (sentinels.length === 0) return

    // Plan 01.8.3-11: both the rootMargin below and the callback's own
    // boundingClientRect threshold now read `this.effectivePinnedPx` (0 or
    // `this.pinnedBandPx`) instead of the row's static full height alone —
    // the same value `applyEffectivePinnedPx` just wrote to the custom
    // property, so the pin trigger and the sticky offset can never
    // disagree about where pinned begins. Falls back to `pinnedBandPx` if
    // called before `effectivePinnedPx` is set (defensive only — mounted()
    // always sets it before the first call).
    const threshold = this.effectivePinnedPx ?? this.pinnedBandPx
    this.pinObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const wrap = entry.target.nextElementSibling
          if (!wrap) continue
          // Plan 01.8.3-05 [Rule 1 - Bug]: `!entry.isIntersecting` ALONE
          // (01.8.3-03's fix, following 01.8.3-RESEARCH.md's diagnosis)
          // is true in TWO cases IntersectionObserver cannot itself tell
          // apart: the sentinel has scrolled UP past the pinned row (the
          // case this whole mechanism exists for), and the sentinel has
          // never yet been scrolled TO — still below the fold, e.g. right
          // after a collapsed section above it (Borradores) is expanded
          // and pushes this section's heading further down. Confirmed live
          // in headless Chrome: expanding Borradores re-triggers
          // `setupPinObserver()` (a fresh `IntersectionObserver` fires an
          // immediate entry for its CURRENT geometry), and Juegos del
          // club's now-far-below-viewport sentinel reported
          // `isIntersecting: false` — correct for "not currently on
          // screen," wrong for this hook's own "has scrolled past" meaning
          // — setting `data-pinned="true"` before the page had scrolled at
          // all. `entry.boundingClientRect.top` DOES distinguish the two
          // (a large positive value when still below the fold, at-or-below
          // `pinnedBandPx` once genuinely stuck) — 01.8.3-03 removed that
          // clause because the ORIGINAL literal `< 0` threshold didn't
          // match `rootMargin`'s own `pinnedBandPx`-derived inset, dominating
          // it and re-opening the ~44px delayed-pin window (the original
          // G-01.8.2-4 report). The fix is not to drop the clause, but to
          // give it the SAME threshold `rootMargin` already uses, so both
          // conditions agree on where "pinned" begins instead of one
          // silently overriding the other.
          //
          // Plan 01.8.3-05 [Rule 1 - Bug]: `toggleAttribute(name, force)`
          // always sets an EMPTY-STRING value when `force` is true — it can
          // never produce the literal string "true" `setAttribute` would.
          // `juegos.css`'s own pinned-band rules select on
          // `[data-pinned="true"]` (an exact-value match, not a presence
          // selector), so the attribute this line wrote could never match
          // that selector: the pinned caption fill has never actually
          // painted since plan 01.8.3-03 shipped it, confirmed via a real
          // headless-Chrome scroll (`data-pinned` read back as `""`, not
          // `"true"`, at every observed pin). Fixed by mirroring this same
          // function's own sibling convention two lines above
          // (`data-pinned-hidden` uses `setAttribute`/`removeAttribute`,
          // never `toggleAttribute`) rather than loosening the CSS
          // selector to presence-only — the exact-value form was written
          // deliberately (twice) and a plain rename carries lower risk of
          // silently also matching some OTHER future `data-pinned="false"`
          // producer.
          const pinned = !entry.isIntersecting && entry.boundingClientRect.top < threshold + 1
          if (pinned) {
            wrap.setAttribute("data-pinned", "true")
          } else {
            wrap.removeAttribute("data-pinned")
          }
        }
      },
      { rootMargin: `-${threshold + 1}px 0px 0px 0px`, threshold: [0, 1] },
    )
    sentinels.forEach((s) => this.pinObserver.observe(s))
  },

  scrollFreshIntoView() {
    const fresh = this.el.querySelector(".pk-admin-juegos-row--fresh")
    if (!fresh || fresh.id === this.lastFreshId) return
    this.lastFreshId = fresh.id
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    fresh.scrollIntoView({ behavior: reducedMotion ? "auto" : "smooth", block: "center" })
  },
}
