# Conventions

## Agent Workflow Rules

- Run `mix precommit` before marking any individual task complete. It is non-mutating;
  if it fails, fix the cause rather than re-running.
- Run `mix quality` once before declaring a phase verified.
- Never run `mix format` or `mix deps.unlock --unused` as part of completing a task —
  formatting changes must be their own isolated commit.
