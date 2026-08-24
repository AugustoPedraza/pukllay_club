# Empty / Loading / Error States

## Design Decisions

Every prior sketch designed the happy path only — a catalog full of games, a detail page for a game
that exists. This sketch designed the four non-happy-path states the real app will hit: initial
loading, a filter combination matching nothing, a failed request, and `/juegos/:id` for a game that
doesn't exist.

**Winner: A — Minimal / Utilitarian**, over **B — Illustrated / Friendly** (shimmering skeletons, an
emoji anchor, warmer conversational copy, and — on the empty-results state — suggestion chips
offering popular categories as an escape hatch). B was more brand-consistent with the project's
"teach the hobby, don't assume familiarity" tone on paper, but was rejected: these are quick,
low-stakes moments a user wants to get *past*, not read copy about — B's warmth risked reading as
trying too hard for what should be a fast, respectful non-event. Get out of the way, don't
over-explain a dead end.

**What A actually is:** flat gray skeleton blocks (poster + caption line, matching the real card's
`.card`/`.poster-art` shape from sketch 002 — same aspect-ratio, same corner radius, so the loading
state doesn't visually jump when real content arrives), no shimmer animation, terse centered copy for
empty/error/404, and one plain filled button (`.retry-btn`) that's either a retry, a "clear filters,"
or a "back to catalog" action depending on which state it's in — never more than one action.

**Copy voice — plain, no jargon, no apology-padding:**
- Empty (filtered, zero matches): "No se encontraron juegos" / "Probá con otros filtros o términos de
  búsqueda." / button: "Limpiar filtros"
- Error (load failed): "No pudimos cargar el catálogo" / "Hubo un problema de conexión." / button:
  "Reintentar"
- 404 (detail, game not found): "Juego no encontrado" / "Este juego no existe o fue removido del
  catálogo." / button: "Volver al catálogo"

Same plain-Spanish, no-jargon voice already established across the card ("difficulty," not raw
min-age) and the about page — terse here specifically because the moment calls for get-out-of-the-way,
not more teaching.

## CSS Patterns

```css
/* Skeleton — matches the real .card shape so loading→populated doesn't jump */
.skel-card { border-radius: var(--radius-md); overflow: hidden; background: var(--color-surface); }
.skel-art { aspect-ratio: 1/1.05; background: var(--color-border); } /* flat, no shimmer */
.skel-line { height: 12px; border-radius: 4px; margin: var(--space-2) var(--space-2) var(--space-3); background: var(--color-border); }

/* Empty / error / 404 — one shared shape, terse copy, one action */
.empty-state, .error-state, .notfound-state {
  text-align: center; padding: var(--space-12) var(--space-4); color: var(--color-text-muted);
}
.empty-state h3, .error-state h3, .notfound-state h3 {
  font-family: var(--font-sans); font-size: var(--text-lg); color: var(--color-text); margin: 0 0 var(--space-2);
}
.empty-state p, .error-state p, .notfound-state p { margin: 0 0 var(--space-3); font-size: var(--text-sm); }
.retry-btn {
  background: var(--color-primary); color: var(--color-primary-content); border: none;
  padding: var(--space-2) var(--space-4); border-radius: var(--radius-sm); font-weight: 600; cursor: pointer;
}
```

## HTML Structures

```html
<!-- Empty results (filtered to zero) -->
<div class="empty-state">
  <h3>No se encontraron juegos</h3>
  <p>Probá con otros filtros o términos de búsqueda.</p>
  <button class="retry-btn">Limpiar filtros</button>
</div>

<!-- Load error -->
<div class="error-state">
  <h3>No pudimos cargar el catálogo</h3>
  <p>Hubo un problema de conexión.</p>
  <button class="retry-btn">Reintentar</button>
</div>

<!-- 404 (detail page, game not found/removed) -->
<div class="notfound-state">
  <h3>Juego no encontrado</h3>
  <p>Este juego no existe o fue removido del catálogo.</p>
  <button class="retry-btn">Volver al catálogo</button>
</div>
```

## What to Avoid

- **Don't add shimmer, emoji anchors, or extra copywriting to loading/empty/error states** — tried
  (variant B) and rejected specifically because these are moments a user wants to get past quickly,
  not moments that benefit from the brand's teaching voice.
- **Don't offer more than one action per state.** B's suggestion-chips escape hatch on the empty
  state was considered redundant once the user can just clear filters themselves — one clear button,
  not a button plus a row of alternative-category chips.
- **Don't let the skeleton loader's shape diverge from the real card** — it reuses `.card`'s own
  aspect-ratio and radius specifically so nothing visually jumps when real content replaces it.

## Origin
Synthesized from sketch: 009
Source file available in: sources/009-empty-loading-error-states/
