---
title: Sync local main to origin/main (106 commits, incl. the sketch wrap-up + share-card.md)
date: 2026-09-22
priority: medium
---

# Sync local `main` → `origin/main`

Left open at the end of quick task `260922-pni` (og-fallback re-bake, PR #64). Nothing is broken;
this is the standing branch-protection divergence CLAUDE.md's "Git Sync Discipline" documents,
surfacing again with a concrete payload now attached to it.

State as of 2026-09-22: local `main` is **106 ahead / 2 behind** `origin/main`.

## What is actually waiting

- **`share-card.md`** (`.claude/skills/sketch-findings-pukllay_club/references/`) — updated by
  `260922-pni` (commit `4abfe3d`) to drop the "asset is stale" warning and document the new
  generator. It was **deliberately excluded from PR #64**: the file does not exist on
  `origin/main` at all, so shipping it alone would have orphaned a reference the `origin/main`
  `SKILL.md` index does not list.
- **The sketch wrap-up commit `8e90928`** — packages 29 sketch findings (052–080). This is why
  `share-card.md` is missing on origin: that skill has **14** references on `origin/main` vs. **23**
  locally. Syncing this commit is what makes `share-card.md` land coherently, index and all.

## How (per CLAUDE.md — `git push origin main` will be rejected)

```
git fetch origin
git checkout -b sync-main-<date> main
git merge origin/main          # resolve conflicts; check planning docs for which side is current
mix quality                    # must be green before pushing
git push -u origin sync-main-<date>
gh pr create
```

After it merges: `git fetch origin && git checkout main && git merge --ff-only origin/main`.

Watch for: the 2 commits local `main` is *behind* are PR #64's own squash (`8078a53`) plus the
docs commit that followed it, so expect the og-fallback paths to conflict — `origin/main`'s side
is the shipped one and its content is identical to local's, so either side resolves the same.

## Not part of this

Optional and unrelated to the sync: WhatsApp / Facebook / X cache OG images on their own servers,
so links shared before 2026-09-22 may still preview the retired `#551670` card until those caches
expire. Facebook's Sharing Debugger forces a re-scrape if you want it sooner. The live asset itself
is verified correct (sha256-identical to the committed file, zero pixels of either retired colour).
