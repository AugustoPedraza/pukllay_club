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
// is mounted on — never an inline style. Visibility checks in this file
// read the RESOLVED `display` (never a class-name string match, and never
// `offsetParent`): a class that sets `display` out-specifies a bare
// `[hidden]` attribute selector, so testing `.hidden` would silently pass
// even while the element is still painted (the 072-080 sketch lineage's own
// guard rule, ported here — see the moduledoc on `AdminComponents.sheet/1`).
//
// FIX (plan 01.8.2-12 Task 3, deferred-items.md's "SEVERE" finding):
// `offsetParent !== null` is unconditionally `false` for a `position: fixed`
// element in Chrome — spec behaviour, not a bug in this app — and
// `.pk-admin-overlay-root` (the element this hook mounts on) IS
// `position: fixed`, so the old `isOpen()` always returned `false`. That
// silently broke Esc, drag-down, the focus trap and focus-return: every one
// of them early-returns on `!this.isOpen()`. Read `getComputedStyle(...)
// .display` instead — exactly what `test/visual/admin_components.mjs`'s own
// `isOverlayOpen` helper does, and exactly what `.pk-admin-overlay--open`'s
// class toggle actually controls (`components.css`: `display: none` at
// rest, `display: block` when open).
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

    // Resolved `display` is the ONE visibility test used anywhere in this
    // file — never a class-name check, and never `offsetParent` (that
    // reads unconditionally `false` for this element's `position: fixed`,
    // regardless of visibility — see this file's header comment). A class
    // that sets `display` always wins over a bare `[hidden]` selector, so a
    // `.hidden`-based test can read "closed" while the element is still on
    // screen; the resolved `display` is the only thing that cannot lie.
    this.isOpen = () => getComputedStyle(this.el).display !== "none"

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
    // Guarded on `document.activeElement === document.body` (plan
    // 01.8.2-12 Task 3, found via CDP tracing while fixing the DOM-removal
    // close path below): `ask-remove` closes THIS sheet and opens
    // `confirm-remove-dialog` in the SAME server diff. LiveView mounts the
    // new dialog hook (which focuses Cancelar in ITS OWN onOpen) BEFORE it
    // destroys this sheet's hook — confirmed empirically by instrumenting
    // both callbacks. An unconditional restore here would therefore run
    // AFTER the dialog already claimed focus and silently steal it back to
    // the row, failing D-19f's "Cancelar carries initial focus" for the
    // EXACT case that matters most (a destructive-action handoff). Only
    // restore when nothing else has claimed focus in the meantime — the
    // browser's own removal-of-focused-element behaviour resets
    // `document.activeElement` to `body` synchronously (confirmed the same
    // way), so `body` reliably means "no other overlay's onOpen ran first".
    this.onClose = () => {
      if (this.lastFocused && document.contains(this.lastFocused) && document.activeElement === document.body) {
        this.lastFocused.focus()
      }
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
    // FIX (plan 01.8.2-12 Task 3): the shipped call sites (`staff_live/
    // index.ex`'s `:if={@selected_staff}`/`:if={@confirm_remove}`) never
    // toggle `pk-admin-overlay--open` OFF on a element that stays mounted —
    // `on_close`/`on_cancel` push a server event that sets the driving
    // assign back to nil, and LiveView removes this whole hooked element
    // from the DOM instead. The MutationObserver above, which only fires on
    // a CLASS mutation of a still-present element, therefore never sees a
    // close for that pattern, and `onClose()` (the focus-return call) was
    // never reached — the sheet closed but focus was never restored to the
    // invoking row. `this.wasOpen` still being `true` here means exactly
    // that: this element is being torn down while it was open, so this is
    // the close this hook's own class-based path would have caught had the
    // caller used a stay-mounted/toggle-class pattern instead. Guarded on
    // `wasOpen` so a genuinely-already-closed (stay-mounted) element being
    // destroyed later — its own class-based close already ran `onClose()`
    // and flipped `wasOpen` to `false` — never double-fires focus-return.
    if (this.wasOpen) this.onClose()
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
