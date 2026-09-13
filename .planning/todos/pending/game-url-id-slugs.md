---
title: Implement id-slug game URLs (/juegos/137-catan)
date: 2026-09-13
priority: medium
context: /gsd-explore "Slugs in game URLs for SEO?" — see .planning/notes/game-url-slug-format.md
---

# Implement id-slug game URLs

Change game detail URLs from `/juegos/137` to `/juegos/137-catan`. No schema change —
the slug is derived from `name` at render time; the id stays the lookup key.

## Scope

- **Slugify** (`name` → slug): transliterate accents (`búsqueda` → `busqueda`), downcase,
  non-alphanumerics → `-`, collapse/trim dashes, cap ~60 chars. Keep `(expa)`/`(2022)`
  noise for now — slug follows the name if names are cleaned later.
- **`Phoenix.Param` for `Game`** → `"#{id}-#{slug}"`, so every `~p"/juegos/#{game}"`
  (`GameCard`, `GamePreview` `detail_path/2`) picks it up automatically.
- **Route** stays `live "/juegos/:id"`; lookup parses the leading integer.
- **301 redirects** in the `GameSEO` plug (HTTP request, before LiveView mount) when the
  slug is missing or stale: `/juegos/137` and `/juegos/137-old-name` → `/juegos/137-catan`,
  preserving the query string (`?from=`). Live navigation: `push_patch` to fix the path.
- **Call sites passing `id` directly** must pass the struct instead:
  `lib/pukllay_club_web/seo.ex` `canonical_url/1`, `sitemap_controller.ex` url entry,
  and the share control's canonical-URL builder.

## Tests

- slugify edge cases (accents, punctuation, `(expa)`, apostrophes, length cap, empty result)
- canonical `<link>`, `og:url`, JSON-LD `url`, sitemap `<loc>` all emit the id-slug form
- 301 from bare id and from stale slug, query string preserved; unknown id still 404s
