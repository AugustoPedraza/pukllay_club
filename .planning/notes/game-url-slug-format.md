---
title: Game URL format — id-prefixed slugs (/juegos/137-catan)
date: 2026-09-13
context: /gsd-explore "Slugs in game URLs for SEO?"
---

# Game URL format decision

**Decision:** game detail URLs use `/juegos/<id>-<slug>` (e.g. `/juegos/137-catan`),
not bare slugs (`/juegos/catan`) and not bare ids (current `/juegos/137`).

## Goals

Both: (1) a modest search-ranking signal from keywords in the URL, and (2) links that read
as trustworthy when shared (WhatsApp, Google results) instead of looking like a DB row.

## Why id-prefix over bare slug

- **Messy names (dev DB, 434 games, all unique):** e.g. `Everdell Spirecrest(expa)`,
  `Wonderland's War (2022)`, `undaunted: north africa`. Names are likely to be cleaned up
  later; a bare slug would either freeze the ugly form forever or need a slug-history table.
- **Renames self-heal:** lookup is by id, so a stale slug just 301s to the current one.
- **No schema change, no collisions:** slug is derived from `name`, never stored.
- Trade-off accepted: slightly noisier URL than `/juegos/catan`.

## Context

- No `/juegos/<id>` links were in real use at decision time (only a few test shares), so
  the switch needs no migration — redirects are a safety net, not a legacy obligation.
- Phase 01.8's canonical/`og:url`/JSON-LD/sitemap/share URLs all derive from one URL
  builder pattern, so the change is centralized.

Implementation: `.planning/todos/pending/game-url-id-slugs.md`
