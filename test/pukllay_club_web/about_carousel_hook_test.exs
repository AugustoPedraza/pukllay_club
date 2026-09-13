defmodule PukllayClubWeb.AboutCarouselHookTest do
  # Source-contract regression gate for WINDOWS #7 / debug session
  # about-rail-dot-click-pause: tapping, clicking, or keyboard-pressing a
  # photo-rail dot on /quienes-somos paused auto-advance forever, because the
  # dot click path (onClick, on the hook root) set `paused = true` with no
  # resume, while the only resume paths (onPointerDown's 6s timer,
  # onMouseLeave) were registered on [data-rail], a SIBLING of [data-dots],
  # not an ancestor.
  #
  # ExUnit cannot run the hook's real setTimeout/click timers — the DOM here
  # is server-rendered HTML with no live browser event loop behind it. The
  # actual timer behaviour (dot tap arms a 6s resume, keyboard press does the
  # same, a swipe after a dot tap restarts the window, mouse-on-rail keeps it
  # paused) was proven separately by an out-of-tree Node execution of the
  # real hook source, extracted verbatim from about_live.ex and mounted
  # against a DOM stub with real event bubbling and fake timers (quick
  # 260912-rwu Task 2). This file pins the STRUCTURAL contract that makes
  # that proof valid: one shared pause-then-resume helper, called from both
  # the click and pointerdown paths, with no separate pause-only assignment
  # anywhere.
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # about_live.ex holds TWO colocated hooks (.AboutCarousel and
  # .AboutHeaderMorph) in one file. A bare `File.read! |> String.contains?`
  # check against the whole file would be satisfied by either hook's code —
  # scoping to THIS hook's own <script> block is what makes these assertions
  # meaningful (same idiom as about_header_morph_test.exs).
  defp about_carousel_hook_source do
    source = File.read!("lib/pukllay_club_web/live/about_live.ex")

    case Regex.run(~r/name="\.AboutCarousel">\s*(.*?)<\/script>/s, source) do
      [_, body] ->
        # JS comments are prose, not code — a code token quoted inside a
        # comment must never satisfy or break a gate (same reasoning as the
        # CSS strip_comments/1 idiom elsewhere in this suite).
        String.replace(body, ~r{^\s*//.*$}m, "")

      nil ->
        flunk("No .AboutCarousel colocated hook <script> block found in about_live.ex")
    end
  end

  # Captures a `this.<member> = (...) => { ... }` arrow-function body, lazily
  # up to the first line holding only a closing brace. Works for both plain
  # statement bodies (onClick, onPointerDown, onMouseEnter, onMouseLeave) and
  # a body containing a single-line nested arrow function (pauseThenResume's
  # inner `setTimeout(() => { ... }, 6000)`), since that inner brace never
  # sits alone on its own line.
  defp handler_body(hook_source, member) do
    escaped = Regex.escape(member)

    case Regex.run(
           ~r/this\.#{escaped}\s*=\s*\([^)]*\)\s*=>\s*\{(.*?)^[ \t]*\}[ \t]*$/ms,
           hook_source
         ) do
      [_, body] -> body
      nil -> flunk("Could not find this.#{member} handler body in the .AboutCarousel hook")
    end
  end

  # Same shape as handler_body/2, for the object literal's destroyed()
  # method, which has no `this.<name> =` prefix.
  defp destroyed_body(hook_source) do
    case Regex.run(~r/destroyed\(\)\s*\{(.*?)^[ \t]*\}[ \t]*$/ms, hook_source) do
      [_, body] -> body
      nil -> flunk("Could not find destroyed() body in the .AboutCarousel hook")
    end
  end

  describe "a dot tap arms the 6s resume (WINDOWS #7)" do
    test "the click listener sits on the hook root, which contains [data-dots]" do
      hook = about_carousel_hook_source()

      assert hook =~ ~s|this.el.addEventListener("click", this.onClick)|,
             "Expected the click listener to stay registered on this.el (#about-carousel), " <>
               "the ancestor that contains [data-dots] — moving it elsewhere would break dot " <>
               "activation entirely."
    end

    test "onClick calls this.pauseThenResume() instead of assigning paused directly" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "onClick")

      assert body =~ "this.pauseThenResume()",
             "Expected onClick to call this.pauseThenResume() so a tapped dot arms the 6s " <>
               "resume timer, the same as a rail swipe."

      refute body =~ "this.paused = true",
             "onClick must not assign this.paused directly — a pause-only assignment with no " <>
               "armed resume is exactly the WINDOWS #7 bug (dot tap pauses autoplay forever)."
    end
  end

  describe "a keyboard dot press arms the resume too (Enter/Space fire click with no pointerdown)" do
    test "the dots render as native button[type=button], so Enter/Space fire click with no pointerdown",
         %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)
      dots = LazyHTML.query(doc, "#about-carousel [data-dots] button[type=\"button\"]")

      assert Enum.count(dots) == 5,
             "Expected 5 native button[type=\"button\"] dots — native buttons fire a click " <>
               "event for Enter/Space with no pointerdown, so the resume must be armed from the " <>
               "click path alone, never from onPointerDown."
    end

    test "onClick arms the resume in the CLICK path itself, not only via pointerdown" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "onClick")

      assert body =~ "this.pauseThenResume()",
             "A keyboard-activated dot (click, no pointerdown) only recovers if onClick itself " <>
               "arms the resume — a fix that only patched onPointerDown would still leave " <>
               "keyboard users permanently paused."
    end
  end

  describe "a swipe after a dot tap restarts the 6s window" do
    test "the pointerdown listener stays registered on the rail" do
      hook = about_carousel_hook_source()

      assert hook =~ ~s|this.rail.addEventListener("pointerdown", this.onPointerDown)|,
             "Expected onPointerDown to stay registered on this.rail — the rail remains the " <>
               "swipe/hover surface per the user's fix decision; dots are covered by the click " <>
               "path instead."
    end

    test "onPointerDown calls this.pauseThenResume() and nothing else" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "onPointerDown")

      assert body =~ "this.pauseThenResume()",
             "Expected onPointerDown's body to call this.pauseThenResume(), sharing the same " <>
               "helper the click path uses."

      refute body =~ "this.paused = true",
             "onPointerDown must not assign this.paused directly anymore — that would be a " <>
               "second, divergent pause path instead of the one shared helper."

      refute body =~ "setTimeout",
             "onPointerDown must not arm its own setTimeout — arming the timer is the shared " <>
               "helper's job, not each caller's."
    end

    test "the helper clears the previous timer before arming a new one, so a later swipe restarts the window" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "pauseThenResume")

      {clear_pos, _} = :binary.match(body, "clearTimeout(this.resumeTimer)")
      {arm_pos, _} = :binary.match(body, "this.resumeTimer = setTimeout(")

      assert clear_pos < arm_pos,
             "Expected clearTimeout(this.resumeTimer) to come BEFORE " <>
               "this.resumeTimer = setTimeout( inside the helper — clearing first is what lets " <>
               "a later swipe restart the 6s window instead of racing the earlier timer."
    end

    test "the hook declares exactly one setTimeout( call (one resume timer, no second timer path)" do
      hook = about_carousel_hook_source()

      matches = Regex.scan(~r/setTimeout\(/, hook)

      assert length(matches) == 1,
             "Expected exactly one setTimeout( in the .AboutCarousel hook — a second timer path " <>
               "would risk two competing resumes racing each other."
    end
  end

  describe "the pauseThenResume helper contract" do
    test "the helper sets paused, clears the pending timer, and arms a fresh 6000ms resume" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "pauseThenResume")

      assert body =~ "this.paused = true"
      assert body =~ "clearTimeout(this.resumeTimer)"
      assert body =~ "this.resumeTimer = setTimeout("
      assert body =~ "6000"
    end
  end

  describe "mouse resting on the rail keeps it paused (mouseenter cancels the pending resume)" do
    test "mouseenter and mouseleave stay registered on the rail" do
      hook = about_carousel_hook_source()

      assert hook =~ ~s|this.rail.addEventListener("mouseenter", this.onMouseEnter)|
      assert hook =~ ~s|this.rail.addEventListener("mouseleave", this.onMouseLeave)|
    end

    test "onMouseEnter pauses and cancels any pending resume timer" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "onMouseEnter")

      assert body =~ "this.paused = true"

      assert body =~ "clearTimeout(this.resumeTimer)",
             "onMouseEnter must cancel the pending resume timer — otherwise a dot click followed " <>
               "by the mouse resting on the rail within 6s would still resume out from under a " <>
               "resting mouse."
    end

    test "onMouseLeave resumes immediately and clears any pending timer" do
      hook = about_carousel_hook_source()
      body = handler_body(hook, "onMouseLeave")

      assert body =~ "this.paused = false"
      assert body =~ "clearTimeout(this.resumeTimer)"
    end
  end

  describe "no pause-only path (WINDOWS #7 cannot regress silently)" do
    test "the literal this.paused = true occurs exactly twice: the helper and onMouseEnter" do
      hook = about_carousel_hook_source()

      matches = Regex.scan(~r/this\.paused = true/, hook)

      assert length(matches) == 2,
             "Expected exactly 2 occurrences of `this.paused = true` in the .AboutCarousel hook " <>
               "(the pauseThenResume helper and onMouseEnter) — a third occurrence would mean a " <>
               "handler pauses again without going through the shared helper, which is exactly " <>
               "the pause-with-no-armed-resume shape of the original bug."
    end
  end

  describe "DOM premise: the dots live outside the rail (WINDOWS #7 root cause)" do
    test "[data-dots] contains 5 [data-goto] buttons, [data-rail] contains 0", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/quienes-somos")

      doc = LazyHTML.from_document(html)

      dot_gotos = LazyHTML.query(doc, "#about-carousel [data-dots] [data-goto]")
      rail_gotos = LazyHTML.query(doc, "#about-carousel [data-rail] [data-goto]")

      assert Enum.count(dot_gotos) == 5,
             "Expected 5 [data-goto] buttons inside [data-dots]."

      assert Enum.empty?(rail_gotos),
             "Expected 0 [data-goto] elements inside [data-rail] — [data-dots] is a SIBLING of " <>
               "[data-rail], not a descendant, which is why rail-scoped listeners (pointerdown, " <>
               "mouseenter, mouseleave) never see a dot interaction. This is the root cause the " <>
               "click-path fix works around, and it must hold both before and after this plan."
    end
  end

  describe "teardown still tears down everything it registered" do
    test "destroyed() clears the resume timer and removes the click and pointerdown listeners" do
      hook = about_carousel_hook_source()
      body = destroyed_body(hook)

      assert body =~ "clearTimeout(this.resumeTimer)"

      assert body =~ ~s|this.el.removeEventListener("click", this.onClick)|

      assert body =~ ~s|this.rail?.removeEventListener("pointerdown", this.onPointerDown)|
    end
  end
end
