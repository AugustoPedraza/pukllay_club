---
type: quick
slug: 261009-b1n-clean-up-stray-esbuild-tailwind-binaries
date: 2026-10-09
---

# Clean up stray esbuild/tailwind binaries at the repo root

Two untracked build-tool binaries sat at the repo root, left over from
2026-09-24: `esbuild-linux-x64` (10MB) and `tailwind-linux-x64-4.3.0` (118MB).

## Task 1 — Confirm the root copies are dead weight

- `cmp` both against `_build/esbuild-linux-x64` / `_build/tailwind-linux-x64-4.3.0`
- Confirm `config/config.exs` sets no `path:` override for `:esbuild` / `:tailwind`,
  so both Mix tasks resolve under `_build/` (already gitignored)
- Confirm neither file is tracked or was ever committed on any branch

## Task 2 — Delete them and add a root-level ignore guard

- `rm` both root copies
- Append `/esbuild-*` and `/tailwind-*` to `.gitignore` with a comment explaining
  why a root-level copy is always a stray

## Task 3 — Verify the asset pipeline still resolves its binaries

- `mix assets.build` must still run tailwind + esbuild to completion
