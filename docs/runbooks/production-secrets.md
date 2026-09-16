# Runbook: production secrets (GitHub Actions)

Every production secret is a GitHub **repository** secret, read by the workflows under
`.github/workflows/`. Values are never committed. `gh secret list` shows names and dates only.

## Which workflow uses what

| GitHub secret | Used by | Becomes (in the container / job) | Notes |
|---|---|---|---|
| `SECRET_KEY_BASE`, `DATABASE_URL`, `SENTRY_DSN` | `deploy.yml` | same names | Phase 0 |
| `POSTGRES_PASSWORD` | `deploy.yml`, `backup.yml` | same name | db accessory + `pg_dump` |
| `DEPLOY_HOST`, `DEPLOY_SSH_KEY` | `deploy.yml`, `backup.yml` | — | SSH to the GCP host |
| `MAILER_API_KEY` | `deploy.yml` | `MAILER_API_KEY` | Resend sending key (01.8.1-03); boot fails without it |
| `BGG_API_TOKEN`, `R2_ACCOUNT_ID`, `R2_CATALOG_BUCKET`, `GEMINI_API_KEY` | `deploy.yml` | same names | Add-by-BGG enrichment (01.8.1-08) |
| `R2_CATALOG_ACCESS_KEY_ID`, `R2_CATALOG_SECRET_ACCESS_KEY` | `deploy.yml` | **`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`** | Catalog-bucket R2 token (image uploads) |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` | `backup.yml` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `R2_ENDPOINT` | Backup-bucket R2 token (nightly `pg_dump`) |

`R2_PUBLIC_BASE_URL` is not a secret: it lives in `config/deploy.yml` under `env.clear`.

## The two R2 tokens

There are two separate Cloudflare R2 API tokens, one per bucket. Don't merge them:

- **Catalog token.** Object Read & Write on `pukllay-club-catalog` only. It's the same token as
  `r2_access_key_id` / `r2_secret_access_key` in the gitignored `config/dev.secret.exs`. It has
  **no** access to `pukllay-backups` (checked 2026-09-14).
- **Backup token.** Writes `pukllay-backups`. It exists only as the repo-level `R2_ACCESS_KEY_ID`
  / `R2_SECRET_ACCESS_KEY` secrets.

The app always reads `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` (`Catalog.Seed.Credentials`).
`deploy.yml` maps the catalog-named secrets onto those names. Setting the repo-level
`R2_ACCESS_KEY_ID` to the catalog token would silently break the nightly backups.

## Setting or rotating a secret

Paste the value at the prompt, from a normal terminal in the project directory. Don't paste it
into an AI chat, and don't put it on a command line:

```bash
gh secret set NAME
```

To copy a value from `config/dev.secret.exs` without printing it, use a script file rather than a
pasted one-liner. A wrapped paste once split `gh secret set` and echoed a key into a transcript.
Write the value with `IO.write/1` and pipe it into `gh secret set NAME`, sending stderr to
`/dev/null`.

After rotating the catalog token in Cloudflare (R2 → Manage API tokens → Roll), update
`config/dev.secret.exs` **and** both `R2_CATALOG_*` secrets. The next deploy picks them up.
