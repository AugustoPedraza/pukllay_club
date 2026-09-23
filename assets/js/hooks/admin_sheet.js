// AdminSheet — the D-19e/D-19f interaction layer shared by AdminComponents'
// `sheet/1` and `dialog/1` (plan 01.8.2-08). Named `admin_sheet.js` (not
// `.hooks/`-colocated like `CarouselRow`'s `.CarouselScroll`) because both
// call sites need the IDENTICAL behaviour from two DIFFERENT components in
// the same module — a colocated `<script :type={Phoenix.LiveView.ColocatedHook}>`
// block would have to be duplicated verbatim into both `sheet/1` and
// `dialog/1`'s templates, the exact "two independently-declared copies of
// one behaviour" anti-pattern `ui-design-system` SKILL.md warns against.
// Registered as a plain (non-colocated) hook in `app.js`'s `hooks` object —
// `phx-hook="AdminSheet"`, no leading dot (the leading-dot form is reserved
// for `Phoenix.LiveView.ColocatedHook`-compiled hooks only).
//
// Deliberately does NOT route through `core_components.ex`'s `show/2`/
// `hide/2` (T-01.8.2-32, the recorded 01.7 defect: `JS.show` writes inline
// `display:block` and silently overrides a stylesheet's intended
// `display:flex`). Open/closed state lives entirely in ONE stylesheet-owned
// class — `pk-admin-overlay--open`, toggled on the root element this hook
// is mounted on — never an inline style. Visibility checks in this file use
// `offsetParent`, never a class-name string match: a class that sets
// `display` out-specifies a bare `[hidden]` attribute selector, so testing
// `.hidden` would silently pass even while the element is still painted (the
// 072-080 sketch lineage's own guard rule, ported here — see the moduledoc
// on `AdminComponents.sheet/1`).
export default {
  mounted() {
    // The element carrying `phx-hook="AdminSheet"` is always the OVERLAY
    // ROOT (`#{id}` on `sheet/1`/`dialog/1`) — a fixed-position wrapper
    // holding the scrim and the panel as siblings. `data-pk-sheet` marks
    // the sheet variant (drag-down applies); `data-pk-dialog` marks the
    // dialog variant (no drag-down, Cancelar gets initial focus instead of
    // the close ✕ — dialog/1 has no ✕ at all, D-19f).
    this.isDialog = this.el.hasAttribute("data-pk-dialog")
    this.scrim = this.el.querySelector("[data-pk-sheet-scrim]")
    this.panel = this.el.querySelector("[data-pk-sheet-panel]")
    this.closeControl =
      this.el.querySelector("[data-pk-sheet-close]") || this.el.querySelector("[data-pk-dialog-cancel]")
    this.grabber = this.el.querySelector("[data-pk-sheet-grabber]")

    // `offsetParent !== null` is the ONE visibility test used anywhere in
    // this file — never a class-name check. A class that sets `display`
    // always wins over a bare `[hidden]` selector, so a `.hidden`-based
    // test can read "closed" while the element is still on screen; the
    // computed box is the only thing that cannot lie.
    this.isOpen = () => this.el.offsetParent !== null

    this.lastFocused = null

    this.requestClose = () => {
      if (!this.isOpen() || !this.closeControl) return
      // Programmatically clicking the SAME control a pointer click would
      // hit means Esc / scrim / drag-down all execute the exact `phx-click`
      // JS command the caller wired on that control (its `on_close`/
      // `on_cancel` attr) — one path, not three independently-maintained
      // triggers that could drift out of sync with each other.
      this.closeControl.click()
    }

    // ---- Esc ----
    this.onKeydown = (e) => {
      if (e.key !== "Escape" || !this.isOpen()) return
      e.preventDefault()
      this.requestClose()
    }
    document.addEventListener("keydown", this.onKeydown)

    // ---- scrim tap ----
    // The scrim already carries the same `phx-click` the close control does
    // (declared directly in the component's markup), so a real pointer tap
    // works with zero JS. This listener exists so a synthetic/programmatic
    // dispatch on the scrim (assistive tooling, an automated test driving
    // `click()` rather than a real pointer event) is funnelled through the
    // identical `requestClose` path as Esc and drag-down, rather than
    // depending on LiveView's click delegation picking it up a second way.
    if (this.scrim) {
      this.onScrimClick = () => this.requestClose()
      this.scrim.addEventListener("click", this.onScrimClick)
    }

    // ---- drag-down dismissal (sheet only — D-19e) ----
    // Tracks a single active pointer on the grabber or the header; past a
    // 25%-of-panel-height threshold on release, the sheet closes, otherwise
    // it snaps back. Only ever writes `transform`/`transition` inline
    // styles — never `display` — so it cannot collide with the stylesheet-
    // owned open/close class T-01.8.2-32 requires.
    if (!this.isDialog && this.panel) {
      this.dragHandle = this.grabber || this.panel.querySelector(".pk-admin-sheet__header") || this.panel
      const dragHandle = this.dragHandle
      this.dragStartY = null
      this.dragDelta = 0

      this.onPointerDown = (e) => {
        if (!this.isOpen()) return
        this.dragStartY = e.clientY
        this.dragDelta = 0
        this.panel.style.transition = "none"
        dragHandle.setPointerCapture?.(e.pointerId)
      }
      this.onPointerMove = (e) => {
        if (this.dragStartY === null) return
        this.dragDelta = Math.max(0, e.clientY - this.dragStartY)
        this.panel.style.transform = `translateY(${this.dragDelta}px)`
      }
      this.onPointerUp = () => {
        if (this.dragStartY === null) return
        const threshold = this.panel.getBoundingClientRect().height * 0.25
        this.panel.style.transition = ""
        this.panel.style.transform = ""
        const dragged = this.dragDelta
        this.dragStartY = null
        this.dragDelta = 0
        if (dragged > threshold) this.requestClose()
      }

      dragHandle.addEventListener("pointerdown", this.onPointerDown)
      dragHandle.addEventListener("pointermove", this.onPointerMove)
      dragHandle.addEventListener("pointerup", this.onPointerUp)
      dragHandle.addEventListener("pointercancel", this.onPointerUp)
    }

    // ---- focus trap + focus return ----
    // A MutationObserver on the root's `class` attribute is the open/close
    // signal — the class is the single source of truth for visibility
    // (toggled by whatever `JS.toggle_class`/assign-driven `class={[...]}`
    // the caller uses), so this hook reacts to it rather than owning a
    // second, parallel notion of "open".
    this.focusableSelector =
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

    this.onOpen = () => {
      this.lastFocused = document.activeElement
      const initial = this.isDialog
        ? this.panel?.querySelector("[data-pk-dialog-cancel]")
        : this.panel?.querySelector("[data-pk-sheet-close]")
      initial?.focus()
    }
    this.onClose = () => {
      if (this.lastFocused && document.contains(this.lastFocused)) this.lastFocused.focus()
      this.lastFocused = null
    }

    this.onKeydownTrap = (e) => {
      if (e.key !== "Tab" || !this.isOpen() || !this.panel) return
      const focusable = [...this.panel.querySelectorAll(this.focusableSelector)]
      if (focusable.length === 0) return
      const first = focusable[0]
      const last = focusable[focusable.length - 1]
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
    document.addEventListener("keydown", this.onKeydownTrap)

    this.wasOpen = this.isOpen()
    if (this.wasOpen) this.onOpen()

    this.observer = new MutationObserver(() => {
      const openNow = this.isOpen()
      if (openNow && !this.wasOpen) this.onOpen()
      if (!openNow && this.wasOpen) this.onClose()
      this.wasOpen = openNow
    })
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
  },

  destroyed() {
    document.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("keydown", this.onKeydownTrap)
    this.scrim?.removeEventListener("click", this.onScrimClick)
    this.observer?.disconnect()
    const dragHandle = this.dragHandle
    if (dragHandle) {
      dragHandle.removeEventListener("pointerdown", this.onPointerDown)
      dragHandle.removeEventListener("pointermove", this.onPointerMove)
      dragHandle.removeEventListener("pointerup", this.onPointerUp)
      dragHandle.removeEventListener("pointercancel", this.onPointerUp)
    }
  }
}
