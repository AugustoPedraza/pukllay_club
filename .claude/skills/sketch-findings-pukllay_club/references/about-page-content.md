# About Page Content

## Design Decisions

**Alternating Bands (winner over Single Flowing Scroll and Narrative + FAQ Accordion).**
Full-width bands alternate background tint and left/right image + text layout, marketing-page
style, for the four required sections (mission, how it works, the club, FAQ). Rejected: a single
flowing scroll (cheapest, most textual, but reads as a plain "about" wall of text) and a
narrative-plus-accordion hybrid (icon step-cards for "how it works" + collapsible FAQ — more
net-new component work than justified here).

**Each band's static placeholder became a working image carousel** (arrows + dots, 3 slides)
instead of one static gradient hero — a real "club" section will eventually have several photos
(meetups, game shelf, people playing), not one hero image per section. Structurally this is a real
`<img>` carousel once photography exists; the sketch's slides are gradient-tinted placeholders
standing in for photos.

**FAQ collapsed into a simpler closing band**, not the full interactive accordion explored in the
rejected variant C — Q&A content here reads better as a scannable closing section than as
collapsible content at the bottom of an already-long page (open question in the README: does hiding
content by default work against a page whose whole point is explaining things to newcomers — worth
revisiting if the FAQ list grows much longer).

**Real content is deliberately deferred.** The layout holds roughly-real copy lengths and a
multi-image carousel now, so it won't need structural rework once real content lands — writing the
actual mission statement / club photos / FAQ answers is a separate content task, not blocked on
this layout decision.

## CSS Patterns — the gutter-padding bug (real, worth remembering generally)

The tinted "Cómo funciona" band applied `--pk-gutter` horizontal padding **twice** — once on its
full-bleed wrapper, again implicitly via its inner `max-width: 1100px` box — so its content sat
~2rem wider than the flanking non-tint bands on desktop. Invisible on mobile (viewport already
narrower than 1100px, so the double-padding never has room to manifest) — this exact class of bug
only shows up above the content's own max-width, so verify full-bleed tinted sections at desktop
width specifically, not just mobile.

```css
/* WRONG — double gutter on tinted bands only */
.band.is-tinted { padding: var(--space-8) var(--pk-gutter); }
.band-inner { max-width: 1100px; margin: 0 auto; padding: 0 var(--pk-gutter); }

/* FIXED — full-bleed wrapper carries vertical padding only;
   .band-inner alone carries the horizontal gutter, matching non-tint bands' box math exactly */
.band.is-tinted { padding: var(--space-8) 0; }
.band-inner { max-width: 1100px; margin: 0 auto; padding: 0 var(--pk-gutter); }
```

## HTML Structures

```html
<section class="band is-tinted">
  <div class="band-inner band-split">
    <div class="band-visual">
      <div class="band-carousel" data-carousel>
        <div class="slide is-active">...</div>
        <div class="slide">...</div>
        <div class="slide">...</div>
        <button class="cs-arrow prev">‹</button>
        <button class="cs-arrow next">›</button>
        <div class="cs-dots"></div>
      </div>
    </div>
    <div class="band-text">
      <h2>{section title}</h2>
      <p>{section copy}</p>
    </div>
  </div>
</section>
```

## What to Avoid

- Don't apply gutter padding on both a full-bleed wrapper and its inner max-width box — pick one.
- Don't build the FAQ as a full accordion component before there's enough Q&A volume to justify
  hiding content by default on an explanatory page.
- Don't treat the band visuals as final — they're gradient placeholders standing in for real club
  photography that doesn't exist yet (still true as of sketches 045-049 below — no real photos
  have been sourced).

---

## 2026-09-02 update (sketches 045-049) — real-page revision, not greenfield

Sketch 004 above designed the About page before it existed. Sketches 011 (full-shell-composition)
and 01.1-02-PLAN.md then shipped the real version — the alternating-bands/carousel structure
survived, but the FAQ became a dark `pk-band-dark` band (not the plain closing band 004
described), and the section set changed. This round (045-049) is a revision of that SHIPPED page
based on real developer feedback, not a continuation of 004's original exploration.

### Header + isologo entrance (045)

The About page's header behaves differently from the rest of the site: it starts fully hidden
(transparent, `pointer-events: none`) instead of the always-visible `is-scrolled`-tinted header
every other page uses. The brand isologo (`priv/static/images/isologo-*.png`, already shipped)
auto-fades-in at 180px in the hero **on a timer** (~500ms after load, independent of scroll) —
never scroll-triggered — then rides with the page exactly like normal content (1:1, no easing)
until it's about to scroll behind where the header sits. At that precise geometric crossing point
it snap-morphs into the header's small (32px) brand-slot mark, revealing the header's wordmark +
a "Volver a la ludoteca" link. Scrolling back up reverses at the same crossing point, no repeat
of the one-time entrance glow.

**Implementation mechanic** (real code, not sketch-only): don't drive this off a percentage-of-
viewport-height scroll threshold — that felt arbitrary and "jumpy." Instead compare the mark's
natural position (read live from the hero section's own `getBoundingClientRect()`, which already
tracks scroll 1:1 with no extra machinery) against the header's target rect on every scroll frame
(rAF-throttled). Below the crossing point: position the mark directly from the natural rect, no
CSS transition (must track pixel-for-pixel). At the crossing point: the ONE eased transition,
both directions.

**Real bug hit and fixed during sketching:** the first attempt created one `<img>` mark per size
variant, all living outside their hidden tab containers — inactive variants computed position
against a `display:none` (zero-size) hero, producing a stray fragment plus overlapping glow
animations. Fixed by using a single reused mark element, reconfigured per active state, never
multiple marks coexisting.

### Photo rail + mobile hero (046)

Auto-advance the photo rail (4s interval) by extending the *existing* shipped `.AboutCarousel`
scroll-snap mechanism with a timer — reuse its pause-on-hover/touch/focus logic rather than
building a second carousel implementation. Rejected: a continuous non-stop "drift" marquee (no
discrete slides, no dots) and a Ken-Burns zoom-while-active variant — both added complexity the
"subtle" brief didn't ask for.

Mobile hero tagline replaced: "Nos juntamos todos los sábados a jugar." → **"Volvé a jugar. Volvé
a encontrarte."** (echoes the "Conectá jugando" headline's theme; earlier drafts mentioning
"sábados" explicitly were rejected as redundant with the FAQ's own day/time answer, and drafts
aiming for "excited/salesy" were rejected in favor of understated-inspirational).

**No real club photography exists yet** — carried forward from 004's original flag, still true.

### Content-band copy (047) — includes a real factual bug fix

The developer wrote the final "Qué hacemos" / "Nuestra historia" / "Juntadas" copy directly rather
than picking between AI drafts — it's meaningfully stronger than anything drafted in this session
(concrete: "De más de 400 juegos elegimos la selección del día"; and it surfaces a fact neither AI
round had — the club represents the province at national events, which is *why* it draws players
from across Argentina and international travelers).

**Real bug found and must be fixed on implementation:** the shipped About page's "Nuestra
historia" band says "Empezamos en 2024" — this is factually wrong. The real origin is **April
2021** (5+ years running as of 2026), with the club representing the province at national events
and hosting travelers from France, Spain, and Portugal. This correction is independent of
everything else in this round — flag it even if the rest of the copy rewrite is deferred.

Also: don't assume the reader knows what a "ludoteca" is (plain-Spanish teaching principle, same
one CATALOG's weight-band/mechanic-chip copy already follows) — describe the concept ("una
selección curada," not "the whole ludoteca") rather than relying on the word alone. "Qué hacemos"
now links into the "Juntadas" section below it.

### FAQ band + Contacto rebuild (048) — a real shared-class width bug, not FAQ-specific

**The FAQ band's purple stays exactly as shipped** (`background: var(--color-primary); color:
var(--color-primary-content)`) — confirmed as the official color after comparing against a
deeper-gradient and a soft-bleed-edge alternative, both rejected. This was scoped to the About
page only; a site-wide rollout of this purple as a more prominent brand color was explicitly
deferred, not decided against.

**Real root-cause bug: `.pk-band-inner`'s `max-width: 64rem` is narrower than the shell's own
`max-w-7xl` (80rem)** used by the header, footer, and the hero (which sets its own width and
never goes through `.pk-band-inner`). This affects **every** content band on the page — Qué
hacemos/Historia, FAQ, Juntadas/Contacto, the closing band — not just the FAQ band the developer
originally flagged. Fix: widen the shared `.pk-band-inner` class to 80rem; this corrects every
band in one change, not a per-band patch.

**Corrected pricing FAQ answer** (was wrong — said free, actually $5.000 reserved / $7.000 at the
door): "Reservá tu lugar por $5.000. ¿Venís de sorpresa? Son $7.000 — pero siempre hay lugar para
vos."

**Contacto rebuilt as ONE merged card**, not a two-column grid of mismatched boxes (a card next to
a separately-sized map thumbnail broke the page's rhythm) — links + map thumbnail live inside the
same card, same "shared edge, no floating pieces" precedent detail-page-layout.md's masthead-
grouping finding (sketch 037) already established. Icons/links reuse the exact pattern the
footer's shipped `social_links/1` already ships (real SVGs, real `ClubLinks` URLs) — don't
reinvent them for this card. Map thumbnail is a static image linking out to Google Maps (not an
embedded iframe, not a bare text link) — **no real map image exists yet**; sourcing one (manual
screenshot vs. Google Static Maps API, which needs a key and has usage cost) is implementation
detail, not resolved here.

**Vertical rhythm:** match the shipped `.pk-band`'s real `4.5rem` (72px) padding on every color
treatment — an early draft used an invented 56px value and felt inconsistent once compared
side-by-side with the rest of the page.

### Closing CTA de-duplication (049)

The closing "Nos vemos el sábado" band repeated WhatsApp + Instagram buttons that the rebuilt
Contacto card (048) directly above it already owns — that repetition, not the band's existence,
was the real "kills the rhythm" complaint. Fix: replace the button pair with the single "Sumate"
CTA already used in the hero (same brand element reused, not a new one).

**Real bug found and fixed:** on the mobile sticky CTA bar, the button is stretched to
`width: 100%`, but its class only set `display: inline-flex; align-items: center` — with no
`justify-content: center`, an `inline-flex` box left-aligns its content by default, so the label
would sit at the left edge of the full-width pill instead of centered. Fix: add
`justify-content: center` — this makes no visual difference on desktop (already centered via the
parent's `text-align: center`, since `inline-flex` is still an inline-level box for outer layout)
but is required for the full-width mobile case.

**Confirmed already correct, no change needed:** the mobile CTA bar (`.pk-about-cta-bar`) is
already `position: fixed` with no scroll-hide/retract logic — genuinely always-visible today.
Full mobile scroll length (hero → photos → Qué hacemos/Historia → FAQ → Contacto → closing) was
walked section-by-section and confirmed reasonable — no section needs trimming for density.

## Isologo Scroll-Morph Companion Wordmark (sketch 050)

The About hero's isologo scroll-morphs into the header on scroll (045's mechanic). It never
carried a text label — a first-time visitor scrolling saw a large graphic mark with no readable
name until it docked. Fix: bake a "PUKLLAY CLUB" companion wordmark into the mark's own box, so
it scales/fades in lockstep as the mark shrinks toward the header.

**Winning treatment:**
- Companion text lives *inside* the isologo's element (absolutely positioned below the image, not
  affecting the box's own size math) — travels and shrinks with the mark itself, "melting into"
  the header's real wordmark as it docks.
- Size: ~25px at rest (`nameScale: 0.135` of the mark's own size), tight letter-spacing
  (`0.02em`). Larger sizes (27px+) read as competing with the H1 for attention; smaller (~17px)
  read as too quiet.
- `font-weight: 400` always — Bebas Neue is self-hosted at weight 400 ONLY in the real app
  (`assets/css/app.css`); anything heavier is a silent browser-faked bold the codebase explicitly
  avoids elsewhere.
- The mark anchors to an **in-flow spacer** as the first child of `.hero`, not the hero
  *section's* own top edge — this is what lets mark + companion + eyebrow + H1 + subtext + CTA
  all center together as one grouped block via the flex column's own gap, instead of the mark
  floating disconnected near the section's top with an arbitrary gap to the rest of the content.
- The hero's eyebrow line ("Club de juegos de mesa · Jujuy") hides the instant the mark docks and
  reappears the instant it undocks — reads the *same* `docked` boolean that drives the header
  reveal and the companion-text fade, so all three change at the identical crossing-point instant
  in both scroll directions. Don't gate this on scroll position/viewport height — tie it to the
  shared dock-state boolean.

**Real bug found + fixed (theme-level, affects every sketch):** the shared sketch theme
(`themes/default.css`) only declared `src: local("Bebas Neue")` for the display font — no actual
webfont file. On any machine without that font installed, it silently fell back to a generic
system sans, rendering "wrong." Fixed by adding the real self-hosted `.woff2` as a fallback source.

**Real bug found + fixed (header layout):** the header's `.brand-slot` never reserved a box for
the mark icon before the wordmark text (production's real markup always renders an `<img>` there
first). Without that reserved space, a docked mark lands flush on the slot's own left edge,
overlapping the first few letters of "PUKLLAY CLUB". Fix: reserve a `width`/`height` spacer
matching the docked mark's size (`DOCK_SIZE`, 32px) as the first flex child, before the text.

## About Page — CTA Rhythm & Band Backgrounds (sketch 051, 14 rounds)

Composed the entire About page (hero → photo rail → content → FAQ → Juntadas/Contacto → Cierre)
at real spacing for the first time, to check how the four CTA touchpoints (hero Sumate, Contacto's
reach-out links, closing-band Sumate, mobile sticky Sumate bar) read together.

**Contacto card:**
- No card chrome (background/padding/border-radius) at any width — matches Juntadas' plain
  background exactly, so the two columns read as one consistent pair, not "text column + boxed
  CTA card." This was a multi-round arrival: card chrome first stripped mobile-only (round 2),
  then dropped on desktop too (round 8) once the whole direction proved out.
  Reason it needed to go: a second heavy, differently-colored card sitting right above the closing
  CTA read as a redundant "ask" competing with Cierre's own Sumate button.
- Contact links (WhatsApp/Instagram/Facebook) are **soft accent-tinted chips** (icon + text,
  `background: var(--color-accent-bg)`) — not icon-only circles (tried and rejected: "breaks the
  rhythm," reads too quiet/footer-like next to the bold text-bearing Sumate buttons elsewhere on
  the page) and not `.btn-sumate`-shaped pills either (would make "reach out" read as the same
  commitment level as "join").
  - On mobile (≤639px), the label drops and the chip becomes icon-only + circular, **centered**
    with a generous gap (not edge-`justify`-ed, and not left-aligned) — purely a space-fit
    constraint (measured: 3 fully-labeled chips need ~387px, a 375px phone's available width is
    ~327px), not a style change.
- The Maps thumbnail belongs with **Juntadas**, not Contacto — it names Juntadas' real-world
  meeting location; Contacto is about reach-out channels, not location. (This reopens sketch
  048's original placement — flag for developer review before shipping.)

**Cierre (closing CTA band):**
- Full-screen on desktop (`min-height: 100vh`, flex-centered, heading scaled up to
  `clamp(2rem, 4vw, 3rem)`) — makes the close a real destination-feeling moment instead of the
  shared 72px band padding every other section uses. Desktop-only; mobile keeps the compact band.
- `padding-top` equal to the fixed header's own height (65px) on the full-screen desktop version —
  pure `align-items: center` in a 100vh box splits leftover space evenly by construction, but the
  docked header visually eats into the top gap while nothing touches the bottom gap, so the *true*
  split is even but the *visible* one isn't. Compensate with padding, don't just trust centering.
- No duplicate Sumate button on mobile ≤480px (same threshold the real sticky CTA bar appears at,
  not the general 640px mobile breakpoint — there's a 480-639px range with no sticky bar, so
  hiding the button any earlier leaves a gap with no visible CTA at all).
- All internal spacing (heading → button → meta line) driven by ONE flex `gap` on the content
  column, not per-element margins — this is what "consistent rhythm across mobile/desktop" means
  in practice: one rule, unmodified per viewport, rather than two hand-tuned spacing systems.
- Closing meta line: plain signature only (`Pukllay Club · San Salvador de Jujuy, Argentina`), no
  trailing social link — a link there is redundant once Contacto covers 3 channels explicitly.
  On mobile, forced to two lines at the natural "·" break point (not wherever the width happens to
  wrap it) via a responsive `<br>`, at a smaller size (10px) than the base line height needs to
  produce genuinely 2 lines, not 3.

**Band backgrounds (whole-page pattern):** alternate plain/tinted backgrounds between adjacent
bands top to bottom — photo rail (plain) → Qué hacemos/historia (tint, `--color-surface`) → FAQ
(dark/primary — kept as a **one-off highlight**, not folded into the alternation) → Juntadas/
Contacto (plain) → Cierre (tint). The FAQ dark treatment reads as a deliberate "bold stop"; making
every band that dark would have them all compete for the same attention instead of each section
just visually separating from its neighbor.

**Real bugs found + fixed along the way (all from live verification, not code review):**
1. Debug annotation flags (used only in this sketch's own tooling, not a real pattern) were
   positioned *inside* their target element's box and fully covered the compact 48px Sumate
   buttons. General lesson: an annotation overlay needs to sit outside the content box it's
   labeling (`bottom: 100%`), never inside it, regardless of how small the target looks.
2. A shared `.band p` rule (class+type selector) silently beat a single-class `.closing-meta`
   rule's `font-size` in the cascade — the meta line had been rendering at 18px, not the intended
   small size, in every round until a two-line wrap made the size difference visible enough to
   notice. **Lesson: when a shared type+class rule and a target's own single-class rule both set
   the same property, the shared rule wins regardless of source order — qualify the target
   selector with an extra class (or the parent's class) to reliably out-specify it.**
3. A page rebuild (round 9, rewriting Cierre's spacing system) silently dropped the section's
   own `text-align: center` rule in the process. Invisible for single-line content (a short box
   auto-sizes to hug its text, masking the missing alignment) until multi-line text exposed it
   (a short first line sat flush-left in a box sized to a longer second line). **Lesson: when
   rewriting a block's layout rules, audit the FULL set of properties being replaced, not just
   the ones the current change is about — a dropped unrelated property can stay invisible for
   many rounds until content shape changes expose it.**
4. Testing/tooling note: a sketch's own toolbar can visually narrow the page (`body.style.
   maxWidth`) without changing `window.innerWidth`, so it never triggers real `@media`
   breakpoints — this produces misleading "it looks wrong at this width" screenshots that are
   actually just a wide layout squeezed into a narrow box. Fixed generally by loading the sketch
   into a real `<iframe>` at the literal target width instead (its own independent viewport
   responds to `@media` correctly) — reusable pattern for any future sketch needing responsive
   verification.

## Origin
Synthesized from sketches: 004, 045, 046, 047, 048, 049, 050, 051
Source files available in: sources/004-about-page/, sources/045-about-header-scroll-isologo/,
sources/046-about-photo-rail-mobile-hero/, sources/047-about-content-bands/,
sources/048-about-faq-contacto/, sources/049-about-closing-cta-mobile/,
sources/050-about-morph-companion-text/, sources/051-about-full-page-cta-rhythm/
