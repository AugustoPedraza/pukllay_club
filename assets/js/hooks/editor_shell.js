// EditorShell (plan 01.8.2-17, D-27): the game editor's own scroll-driven
// title fade-in — "the title is absent at rest and fades in on scroll,
// keeping `flex: 1` while invisible so nothing slides" (D-19n applied to a
// bar already present, trigger `scrollTop > 46`, per the packaged
// `admin-game-editor.md` reference). Same non-colocated, mount-once,
// window-scroll-driven, purely-client-side-toggle shape as `AdminList`'s
// own page-bar toggle (`assets/js/hooks/admin_list.js`) — a presentational
// class flip costs nothing server-side and never fights a LiveView diff,
// since the class is re-applied idempotently on every scroll tick and on
// every `updated()` patch.
const TITLE_FADE_THRESHOLD = 46

export default {
  // Mounted directly on the top bar element itself (`this.el` IS the bar,
  // `.pk-editor-topbar`) — no separate lookup needed, unlike `AdminList`'s
  // own hook, which mounts on the page's stable wrapper and reaches into
  // several descendants.
  mounted() {
    this.onScroll = () => {
      const titled = window.scrollY > TITLE_FADE_THRESHOLD
      this.el.classList.toggle("is-titled", titled)
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    // A freshly mounted page always starts at scrollTop 0, so this is a
    // no-op in practice — kept for a browser restoring a mid-scroll
    // position on reconnect (same rationale `AdminList` documents for its
    // own mount-time call).
    this.onScroll()
  },

  updated() {
    this.onScroll?.()
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll)
  },
}
