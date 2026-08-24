// Sets `data-theme`/`data-theme-source` on <html> before the body paints, to
// avoid a flash of the wrong theme. Loaded as a separate, non-deferred
// <script src=...> in root.html.heex's <head> (see CLAUDE.md CSP notes) so it
// runs under a strict `script-src 'self'` Content-Security-Policy — it was
// previously an inline <script> block, which a CSP with no 'unsafe-inline'
// silently refuses to execute in a real browser (01-REVIEW.md CR-01).
(() => {
  const systemTheme = () => (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")

  const setTheme = (theme) => {
    if (theme === "system") {
      localStorage.removeItem("phx:theme")
      document.documentElement.setAttribute("data-theme", systemTheme())
      document.documentElement.setAttribute("data-theme-source", "system")
    } else {
      localStorage.setItem("phx:theme", theme)
      document.documentElement.setAttribute("data-theme", theme)
      document.documentElement.setAttribute("data-theme-source", "user")
    }
  }

  if (!document.documentElement.hasAttribute("data-theme")) {
    setTheme(localStorage.getItem("phx:theme") || "system")
  }

  window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"))
  window.addEventListener("phx:set-theme", (e) => setTheme(e.target.dataset.phxTheme))

  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
    if (document.documentElement.getAttribute("data-theme-source") === "system") {
      document.documentElement.setAttribute("data-theme", systemTheme())
    }
  })
})()
