---
type: quick
slug: 261009-b1n-clean-up-stray-esbuild-tailwind-binaries
date: 2026-10-09
status: complete
---

# Summary

Deleted 124MB of unused duplicate build-tool binaries from the repo root and
added an ignore guard so they cannot be committed if they reappear.

## What was there

| File | Size | Dated |
|---|---|---|
| `esbuild-linux-x64` | 10,264,728 B | 2026-09-24 |
| `tailwind-linux-x64-4.3.0` | 118,880,576 B | 2026-09-24 |

## Evidence they were dead weight

- **Byte-identical** to the `_build/` copies (`cmp -s` returned equal for both).
  The `_build/` copies are dated 2026-08-25 — the root ones are later duplicates.
- `config/config.exs` sets `version:` but **no `path:`** for either `:esbuild`
  (line 11) or `:tailwind` (line 103). Both libraries therefore fall back to
  `Path.dirname(Mix.Project.build_path())` → `_build/`, which is already
  gitignored. Nothing reads the root copies.
- `git ls-files --error-unmatch` → not tracked. `git log --all --` → never
  committed on any branch.

## Changes

- Deleted both root binaries (124MB freed).
- `.gitignore`: added `/esbuild-*` and `/tailwind-*` under a comment recording
  why a root-level copy is always a stray. Motivated by the Tailwind binary
  being ~118MB and this repo being public. Verified the new rules capture no
  currently-tracked path (`git ls-files | git check-ignore --stdin` → empty)
  and that nothing else at the root matches them.

## Verification

`mix assets.build` ran clean with only the `_build/` copies present:

```
≈ tailwindcss v4.3.0
/*! 🌼 daisyUI 5.5.20 */
Done in 1s
  ../priv/static/assets/js/app.js    379.8kb
  ../priv/static/assets/js/theme.js    1.2kb
⚡ Done in 95ms
```

Either binary is re-downloadable on demand via `mix assets.setup`, so the
deletion is cheap to undo.

## Notes

- Executed inline rather than via gsd-planner + gsd-executor: two
  untracked-file deletions and one `.gitignore` line did not justify the
  subagent round trip.
- Committed on a branch rather than local `main`. `main` was exactly in sync
  with `origin/main` (`rev-list --left-right --count` → `0 0`) and `origin/main`
  is branch-protected, so committing directly to `main` would have created the
  unpushable divergence documented in CLAUDE.md's Git Sync Discipline section.
- `ideas.txt` was also modified in the working tree. Left untouched — unrelated
  to this task.
