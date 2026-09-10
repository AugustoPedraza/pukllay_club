# Quick Task 260910-l7q: Redesign the light/dark color palette as one shared OKLCh ramp so theme roles can literally reuse the same swatch across themes (not just hue-matched), instead of today's 16 fully independent per-theme hexes. Research industry-standard approaches (shared color ramps, token architecture) before proposing the concrete ramp. - Context

**Gathered:** 2026-09-10
**Status:** Ready for planning

<domain>
## Task Boundary

Redesign the light/dark color palette as one shared OKLCh ramp so theme roles can literally reuse
the same swatch across themes (not just hue-matched, which the prior quick task 260910-if9 already
fixed), instead of today's 16 fully independent per-theme hexes. Research industry-standard
approaches (shared color ramps, token architecture) before proposing the concrete ramp.

Triggered by the developer noticing that light's `btn-primary` fill (`#3D096D`) has no relationship
to any dark-mode token — every one of the 8 semantic roles in `daisyui-theme("light")` and
`daisyui-theme("dark")` currently has an independently invented hex, even after 260910-if9 aligned
their hues. The developer wants the two themes to draw from one physical palette, the way a single
brand-purple ramp is worn two ways, not two unrelated 8-color sets that merely share a hue family.

</domain>

<decisions>
## Implementation Decisions

### Reuse scope
- **Everything the contrast budget allows.** Do not pre-restrict which roles may share a literal
  value. The research/audit phase should determine, role by role, which pairs of (light role, dark
  role) CAN share one ramp stop without violating that role's own contrast requirement, and which
  cannot (e.g. a button that must pop on its own theme's background may be structurally unable to
  share a stop with a background role) — report both the sharable set and the ones blocked by
  contrast math, rather than assuming up front that only backgrounds/surfaces qualify.

### Architecture approach
- **Defer to research.** Compare two candidate approaches against how production design systems
  (Radix Colors, Tailwind's palette, Material Design 3, GitHub Primer, etc.) structure this:
  1. New `--pk-ramp-*` tokens as the single source of truth; daisyUI's existing `--color-base-100`/
     `--color-primary`/etc. keep being declared directly per theme as today, but each theme's chosen
     hex must now be picked FROM the shared ramp and documented as such (low blast radius, reuse is
     documented/convention-enforced, not structurally enforced).
  2. daisyUI's `--color-*` slots become `var()` references into `--pk-ramp-*` variables directly
     (higher blast radius — touches daisyUI's own token resolution mechanism — but makes reuse
     impossible to silently drift off-ramp in a future edit).
  Research should recommend one, with rationale grounded in how the surveyed systems actually do it
  and in this project's own constraint of not breaking existing daisyUI component styling or the
  260910-hdc/if9 tripwire tests.

### Ramp granularity
- **~9–12 stops**, matching the common industry pattern (Radix/Tailwind-style 50–950 scales). Confirm
  or adjust this count in the audit based on whether the ramp's real stops can land close enough to
  already-shipped, developer-approved values (light's `#3D096D` button, `--pk-ink-brand`'s `#C791E5`,
  etc.) without forcing a re-litigation of colors the developer already signed off on in prior quick
  tasks (260910-efe/gck/hdc/if9).

### Hue-unification for light's `--color-primary`
- **Move light's `--color-primary` (`#3D096D`, H300.1) onto the shared ramp's fixed hue H313.1.**
  Research surfaced that a single fixed-hue ramp cannot hold both light's current primary hue and
  dark's ladder hue (rotated to H313.1 by 260910-if9) — this decision resolves that conflict in
  favor of one true single-hue ramp, re-opening the color approved in 260910-efe by a small (~13°),
  documented amount. This is also what closes the developer's own original motivating example (the
  "Reservar para el sábado" button's fill vs. dark's `--color-base-200`, currently ΔL 0.4 / ΔH 13.0 —
  blocked only by this hue split). The nearest ramp stop research computed for this move is
  `~#470E5E`; the plan should re-derive the exact value from the final ramp, not treat this hex as
  locked.

### Claude's Discretion
- Whether the shared ramp is generated algorithmically (one hue, computed L/C steps) or hand-tuned
  stop by stop — pick whichever the research phase's industry survey suggests is standard practice
  and whichever better preserves the already-approved anchor colors.
- Whether `--pk-ink-brand` (introduced by 260910-hdc) gets folded into the new ramp as one of its
  named stops, or is left standing alongside the ramp as a pre-existing anchor token the ramp must
  be compatible with. Decide based on whether folding it in changes its value — if it would change
  the already-approved `#C791E5`/light-reads-primary shape, leave it standing and note the ramp stop
  nearest to it instead.
- Exact stop-naming convention (numeric like `--pk-ramp-500`, or semantic-plus-index) — follow
  whichever convention the research survey shows is dominant, for familiarity to future maintainers.

</decisions>

<specifics>
## Specific Ideas

The developer's own framing example: the "Reservar para el sábado" button (`btn btn-primary`) in
light mode fills with `#3D096D` — a color dark enough that it could plausibly ALSO serve as dark
mode's page background or a card surface, rather than dark inventing an unrelated `#361148` for
that role. This is the shape of reuse being asked for: not hue-matching (already done), but literal
value-sharing across different semantic roles in different themes.

No specific ramp values or stop counts are pre-decided beyond the "~9-12" preference above — those
are for the research + planning phases to derive from the real current palette (measured via the
existing `oklch-audit.mjs` instrument from 260910-if9, which should be extended/reused rather than
rebuilt) and from the industry survey.

</specifics>

<canonical_refs>
## Canonical References

- `assets/css/app.css` — the two `daisyui-theme` blocks (light ~line 263, dark ~line 228) are the
  single upstream palette source this task modifies.
- `.planning/quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs` and
  `AUDIT.md` — the OKLCh measurement instrument and its findings from the immediately preceding
  quick task; this task's audit should extend it, not duplicate its OKLCh conversion math.
- `--pk-ink-brand` token and its provenance comment in `assets/css/app.css` (introduced by quick
  task 260910-hdc) — the existing precedent for a theme-scoped `--pk-*` token declared as a variable
  read in light and a concrete value in dark; any new `--pk-ramp-*` tokens should follow its shape
  unless research argues for a different one.
- `.planning/sketches/themes/default.css` and `check-theme-drift.sh` — the sketch-palette mirror and
  its drift gate; any `--color-*` value that moves must stay synced through this.

</canonical_refs>
