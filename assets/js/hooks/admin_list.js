// AdminList — the Juegos screen's own interaction layer (plan 01.8.2-14,
// D-19g-bis/D-19n). Registered as a plain (non-colocated) hook in
// `app.js`'s `hooks` object (`phx-hook="AdminList"`, no leading dot),
// mirroring `AdminRail`'s own non-colocated convention: mounted once on
// the page's stable wrapper (`#juegos-page`) rather than on any
// conditionally-rendered child, since sections/rows come and go as
// groups collapse/expand and as the search narrows the list.
//
// Four independent jobs:
//   1. Expand-keeps-position (D-19g-bis decision 8/18): opening or
//      closing a collapsible section keeps the TAPPED heading exactly
//      where the finger left it — captured on click, corrected after the
//      LiveView diff lands.
//   2. Pinned section captions (D-19n): an IntersectionObserver watches a
//      zero-height sentinel placed just before each section's sticky
//      heading and toggles `data-pinned` on the heading wrap the instant
//      the sentinel scrolls out of view above the fold — the heading
//      gains its `--color-surface` fill ONLY while pinned (juegos.css).
//   3. The pinned page bar (D-19n): `.pk-admin-page-bar` becomes visible
//      (and, per this plan's `components.css` fix, `position: fixed`)
//      once the page title has scrolled behind the 44px band it reserves;
//      `inert` toggles between it and the in-page `back_row/1` so exactly
//      one back control is ever focusable (T-01.8.2-64).
//   4. Scroll a freshly-created draft's row into view once (D-37 gate 4,
//      076's `.fresh` pattern) — the row's own `.pk-admin-juegos-row--fresh`
//      class marks it.
//
// Purely client-driven presentational toggling (page-bar visibility,
// pinned fill) — same shape as `AdminRail`'s `data-pinned-hidden` —
// rather than a LiveView assign updated on every scroll tick, so scrolling
// never costs a server round trip.
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

    this.title = this.el.querySelector(".pk-admin-page-title")
    this.pageBar = document.querySelector(".pk-admin-page-bar")
    this.pageBarBack = this.pageBar?.querySelector(".pk-admin-page-bar__back")
    this.backRow = this.el.querySelector(".pk-admin-back-row")

    this.onScroll = () => {
      if (!this.title || !this.pageBar) return
      const visible = this.title.getBoundingClientRect().bottom <= PAGE_BAR_BAND
      this.pageBar.classList.toggle("pk-admin-page-bar--visible", visible)
      this.pageBarBack?.toggleAttribute("inert", !visible)
      this.backRow?.toggleAttribute("inert", visible)
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    // A freshly mounted screen always starts at scrollTop 0 (D-19n), so
    // running this once at mount is a no-op in practice — kept for the
    // case a browser restores a mid-scroll position on reconnect.
    this.onScroll()

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
