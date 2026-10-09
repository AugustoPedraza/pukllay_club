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
//
// FIX (plan 01.8.3-13, G-01.8.3-4a): the document behind an open sheet or
// dialog was fully scrollable — `onOpen`/`onClose` above manage focus only,
// and no CSS rule locked the document either (see
// `.planning/debug/DEBUG-admin-sheet-modal-contract.md`). The module-level
// counter and saved offset below are shared by EVERY instance of this hook
// on the page (there are 20 exposed `sheet/1`/`dialog/1` call sites across 8
// files sharing this one module) because a sheet->dialog handoff — e.g.
// `staff_live/index.ex`'s `ask-remove` closing `staff-options-sheet` and
// opening `confirm-remove-dialog` in the SAME server diff — mounts the
// SECOND overlay's hook and runs ITS `onOpen` (an acquire) BEFORE LiveView
// destroys the first's hook (whose `destroyed()` runs a release),
// confirmed empirically by instrumenting both callbacks (the same ordering
// this file's own `onClose` comment above already documents for focus). A
// plain boolean toggle would therefore unlock the document while the
// dialog is still open; a reference count does not, because the nested
// acquire only increments — it never re-reads or re-writes the saved
// offset, since the document is already held at a shifted position at that
// point and would read back as (near) zero.
let overlayLockCount = 0
let overlayLockSavedOffset = 0

// Acquire: on the FIRST (0 -> 1) acquire, read the document's current
// scroll offset, write it as a length-valued custom property on `<body>`
// for the CSS lock rule (`components.css`'s `body.pk-admin-overlay-open`)
// to read, then add the lock class. A nested acquire (count already > 0)
// only increments — see this file's header comment above for why the
// offset must not be re-read there.
function acquireOverlayLock() {
  if (overlayLockCount === 0) {
    overlayLockSavedOffset = document.scrollingElement.scrollTop
    document.body.style.setProperty("--pk-admin-overlay-scroll-offset", `${overlayLockSavedOffset}px`)
    document.body.classList.add("pk-admin-overlay-open")
  }
  overlayLockCount++
}

// Release: decrements, never below zero (a stray extra release — e.g. a
// double-fire this file's own per-instance flag already guards against —
// must never make the count negative and thus never "acquire" on the next
// legitimate open without doing the first-acquire work). Only when the
// count reaches zero does it actually unlock: remove the class, remove the
// custom property, and restore the document to the saved offset.
function releaseOverlayLock() {
  if (overlayLockCount === 0) return
  overlayLockCount--
  if (overlayLockCount === 0) {
    document.body.classList.remove("pk-admin-overlay-open")
    document.body.style.removeProperty("--pk-admin-overlay-scroll-offset")
    // FORCE A REFLOW before restoring the offset (found via this task's own
    // live-device tracing — a Rule 1 bug, not a theoretical concern):
    // `document.scrollingElement`'s scrollable height comes from `<html>`,
    // which has NO overflow while `<body>` is `position: fixed` (that is
    // the WHOLE mechanism the lock relies on). Removing the class
    // synchronously updates the CSSOM, but the layout engine does not
    // necessarily recompute `<html>`'s now-restored scrollable height
    // before the very next synchronous line runs.
    void document.body.offsetHeight
    // `{ behavior: "instant" }`, NOT a bare `scrollTop =` assignment — a
    // SECOND, independent Rule 1 bug this same trace caught: `app.css`'s
    // document-wide `html { scroll-behavior: smooth }` (gated only on
    // `prefers-reduced-motion`) makes Chrome ANIMATE even a direct
    // `scrollTop` property write here, so a synchronous read immediately
    // after the assignment measured 0 (the pre-restore value) while the
    // SAME read 200ms later measured the correct restored offset — a plain
    // property write would silently race every synchronous caller (this
    // hook's own tests included) against that animation. `behavior:
    // "instant"` explicitly overrides the page's CSS `scroll-behavior` for
    // this one call, per the CSSOM View scroll API, landing the restore
    // synchronously instead.
    document.scrollingElement.scrollTo({ top: overlayLockSavedOffset, left: 0, behavior: "instant" })
  }
}

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
    // G-01.8.3-4a: per-instance flag so THIS instance's own acquire/release
    // pair can never fire twice (a double `onClose`, or an `onClose`
    // followed by a `destroyed()` release for an already-released
    // instance) — mirrors `wasOpen`'s own role for the focus-return call
    // just below, but tracks the scroll-lock reference this instance holds
    // rather than open/closed state.
    this.overlayLockHeld = false

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
      // G-01.8.3-4a: acquire the document scroll lock. Guarded on
      // `overlayLockHeld` so a MutationObserver firing `onOpen` twice for
      // the same open (should not happen, but this instance's own flag is
      // the cheap defence against it) can never acquire twice.
      if (!this.overlayLockHeld) {
        acquireOverlayLock()
        this.overlayLockHeld = true
      }
      this.lastFocused = document.activeElement
      // Plan 01.8.4-01 (ADD-02): a sheet whose first job is a search field
      // opts in with `data-pk-sheet-autofocus` on that field, and it is
      // looked up BEFORE the close button. The attribute is opt-in, so every
      // shipped sheet keeps focusing its close button exactly as before.
      const initial = this.isDialog
        ? this.panel?.querySelector("[data-pk-dialog-cancel]")
        : this.panel?.querySelector("[data-pk-sheet-autofocus]") ||
          this.panel?.querySelector("[data-pk-sheet-close]")
      initial?.focus()
    }
    // FIX (plan 01.8.3-14, G-01.8.3-4c): the guard that used to live here
    // compared the active element against `document.body` — correct for
    // exactly one of four cases below and silently wrong for another.
    // Measured, twice (on the real sheet, and in isolation with no app
    // code — see `.planning/debug/DEBUG-admin-sheet-modal-contract.md`): a
    // focused element inside a subtree that gains `display: none` via a
    // class toggle reads as STILL FOCUSED inside the SAME MutationObserver
    // microtask this callback runs in, and settles to `body` only after
    // two animation frames — whereas a DOM-removal close resets
    // `document.activeElement` to `body` SYNCHRONOUSLY (the browser's own
    // removal-of-focused-element behaviour). The four cases and their
    // correct outcomes:
    //   1. Class-toggle close (e.g. `add-game-sheet`'s stay-mounted
    //      `open={...}`): the active element at this point is still this
    //      sheet's own close control — inside THIS overlay's own root.
    //      Restore.
    //   2. DOM-removal close (`staff_live`'s `:if={@selected_staff}`
    //      pattern, plan 01.8.2-12 Task 3's own case): the active element
    //      is already `document.body` by the time this runs. Restore.
    //   3. The sheet->dialog handoff (also plan 01.8.2-12 Task 3's case:
    //      `ask-remove` closes THIS sheet and opens `confirm-remove-dialog`
    //      in the SAME server diff): LiveView mounts the new dialog's hook
    //      and runs ITS OWN `onOpen` — which focuses Cancelar — BEFORE
    //      destroying this sheet's hook (confirmed empirically by
    //      instrumenting both callbacks). The active element is Cancelar,
    //      inside a DIFFERENT overlay's own root. Decline — an
    //      unconditional restore here would steal focus back to the
    //      invoking row, failing D-19f for the exact case that matters
    //      most (a destructive-action handoff). Proven on every run by
    //      `test/visual/admin_shell.mjs`'s `checkSheetFocusReturn` case 3.
    //   4. A background control was focused before the close (the user
    //      clicked away while the overlay was open): the active element is
    //      outside this overlay entirely. Decline.
    // The property that actually distinguishes "restore" from "decline" is
    // therefore CONTAINMENT in this overlay's own root — has anything
    // OUTSIDE it claimed focus? — not an equality against `body`, which
    // only accidentally covered case 2. No animation-frame deferral is
    // used or needed: all four cases resolve correctly from state
    // available SYNCHRONOUSLY at this point, and a deferral would reopen
    // the exact interleaving window (a later `onOpen` running before the
    // deferred restore) this guard exists to close.
    this.onClose = () => {
      // G-01.8.3-4a: release the document scroll lock. Guarded on
      // `overlayLockHeld` so a double `onClose` (this instance's own flag,
      // same shape as `wasOpen`'s guard against a double focus-return)
      // can never release twice. Runs unconditionally, before any of the
      // focus-restore early returns below — the release must never sit
      // behind them.
      if (this.overlayLockHeld) {
        releaseOverlayLock()
        this.overlayLockHeld = false
      }

      const toFocus = this.lastFocused
      this.lastFocused = null
      if (!toFocus || !document.contains(toFocus)) return
      const active = document.activeElement
      if (active !== document.body && !this.el.contains(active)) return
      toFocus.focus()
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
    // G-01.8.3-4a: a DEFENSIVE release, independent of `wasOpen` above —
    // `layouts.ex:1619`'s own precedent for exactly this failure mode (its
    // comment: "a LiveView teardown mid-open must never leave the page
    // permanently unscrollable"). `onClose()` just above already releases
    // when `wasOpen` is true, so this line is a no-op on that path (guarded
    // on the same `overlayLockHeld` flag); it only does real work if this
    // instance still holds the lock reference through some path that did
    // NOT run `onClose` first, closing that leak unconditionally rather
    // than trusting `wasOpen` to have covered every teardown shape.
    if (this.overlayLockHeld) {
      releaseOverlayLock()
      this.overlayLockHeld = false
    }
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
