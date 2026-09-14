---
title: Pick transactional email provider, wire Swoosh in prod, set SPF/DKIM
date: 2026-09-13
priority: high
---

# Email provider + DNS for magic-link auth

Blocking prerequisite for staff magic-link login (Staff Admin phase).

- GCP blocks outbound port 25 on the e2-micro → use an HTTP email API through a Swoosh adapter,
  not raw SMTP.
- Candidates to compare during planning: Resend, Brevo, Postmark (free tiers; volume is ~4 staff
  logins). Verify current free-tier limits at decision time — not verified in exploration.
- Configure the adapter in `config/runtime.exs`; API key goes in `.kamal/secrets` as a `secret`
  env var in `deploy.yml`.
- Add SPF + DKIM (and ideally DMARC) records for `pukllay.club` so magic links don't land in spam.
- Verify end-to-end: a real magic link email delivered to Gmail inbox from production.

Context: `.planning/notes/staff-admin-decisions.md`.
