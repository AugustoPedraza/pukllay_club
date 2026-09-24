// AdminRail — the Estantes screen's own interaction layer (plan
// 01.8.2-13, D-08/D-19n). Registered as a plain (non-colocated) hook in
// `app.js`'s `hooks` object (`phx-hook="AdminRail"`, no leading dot — the
// leading-dot form is reserved for `Phoenix.LiveView.ColocatedHook`
// blocks), mirroring `AdminSheet`'s own non-colocated convention: this
// hook is mounted once on the page's own stable wrapper (`#estantes-page`)
// rather than on the rail or the search field directly, because both of
// those are conditionally re-rendered (the rail only exists once a game
// is picked; `:if={@query != ""}` swaps the dropdown's own children) — a
// hook mounted on a conditionally-present element would be torn down and
// remounted on every idle<->answered transition, losing its scroll-
// tracking and listener state each time.
//
// Two independent jobs:
//   1. Scroll the picked copy's cover into view when the rail opens (or
//      when a different copy becomes selected on an already-open rail).
//   2. D-19n's pinned-search hide/return: the SAME search field (never a
//      second, synced copy — see `pk-estantes-search-wrap`'s CSS) hides
//      on scroll-down and returns on scroll-up, never while the field is
//      focused, and never within 140px of the top (a new screen always
//      starts at scrollTop 0, so the pinned state never appears on a page
//      nobody scrolled).
export default {
  mounted() {
    this.searchWrap = this.el.querySelector("#estantes-search-wrap")
    this.searchInput = this.el.querySelector("#estantes-search-input")
    this.lastScrollY = window.scrollY
    this.lastScrolledId = null

    // ---- scroll-to-selected ----
    this.scrollToSelected = () => {
      const selected = this.el.querySelector("[data-pk-rail-selected='true']")
      if (!selected || selected.id === this.lastScrolledId) return
      this.lastScrolledId = selected.id
      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
      selected.scrollIntoView({
        behavior: reducedMotion ? "auto" : "smooth",
        inline: "center",
        block: "nearest",
      })
    }
    this.scrollToSelected()

    // ---- D-19n pinned search ----
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
    window.addEventListener("scroll", this.onScroll, {passive: true})
  },

  // Fires on every LiveView diff touching this hook's subtree — a no-op
  // unless the selected cover actually changed id (guarded by
  // `lastScrolledId` above), so a same-estante rail refresh from a
  // `{:estante_updated, _}` broadcast does not re-scroll on every
  // update, only when the selection itself moved.
  updated() {
    this.scrollToSelected()
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
  },
}
