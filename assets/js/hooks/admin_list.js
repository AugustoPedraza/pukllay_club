// AdminList — the Juegos screen's own interaction layer (plan 01.8.2-14,
// D-19g-bis/D-19n; pinned row rebuilt by plan 01.8.3-01, D-06/D-07/D-09).
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
//      the sentinel scrolls out of view above the fold — the heading
//      gains its `--color-surface` fill ONLY while pinned (juegos.css).
//      Kept byte-identical in plan 01.8.3-01 (D-15's fix is plan 03's
//      job) — including its own use of `PAGE_BAR_BAND` below, which this
//      plan therefore cannot delete despite the constant's stale name.
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
//
// `PAGE_BAR_BAND` is kept, not deleted, despite its name: `setupPinObserver`
// below still reads it and is required to stay byte-identical in this
// plan, so removing the declaration would throw a ReferenceError the
// instant this hook mounts. Plan 03 owns renaming/repurposing it
// alongside its own observer fix (D-15).
const PAGE_BAR_BAND = 44

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

      if (focused || nearTop) {
        this.searchWrap.removeAttribute("data-pinned-hidden")
      } else if (goingDown) {
        this.searchWrap.setAttribute("data-pinned-hidden", "true")
      } else {
        this.searchWrap.removeAttribute("data-pinned-hidden")
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
  },

  setupPinObserver() {
    this.pinObserver?.disconnect()
    const sentinels = [...this.el.querySelectorAll("[data-pk-section-sentinel]")]
    if (sentinels.length === 0) return

    this.pinObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const wrap = entry.target.nextElementSibling
          if (!wrap) continue
          // Pinned means: the sentinel has scrolled fully above the
          // reserved band (not merely "not intersecting" — an element
          // below the viewport is also "not intersecting" and must NOT
          // read as pinned).
          const pinned = !entry.isIntersecting && entry.boundingClientRect.top < 0
          wrap.toggleAttribute("data-pinned", pinned)
        }
      },
      { rootMargin: `-${PAGE_BAR_BAND + 1}px 0px 0px 0px`, threshold: [0, 1] },
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
