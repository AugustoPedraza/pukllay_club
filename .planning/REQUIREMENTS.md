# Requirements: PukllayClub

**Defined:** 2026-09-11
**Core Value:** A member can describe what they want in plain Spanish and find a game that fits —
even without already knowing board-game vocabulary.

## v1 Requirements

Requirements for milestone v1.1 "Sharable Version". Each maps to roadmap phases.

### Production Data

- [x] **SEED-01**: Production's live database has the full game catalog (~400+ games) loaded,
      matching dev — currently empty
- [x] **SEED-02**: A safe, repeatable, documented path exists to (re-)run the seed pipeline against
      production

### SEO

- [x] **SEO-01**: Every game detail page has a unique, real meta description
- [x] **SEO-02**: Catalog card and hover-preview images have real, descriptive `alt` text
      (currently `alt=""`)
- [x] **SEO-03**: `robots.txt` allows crawling and references `sitemap.xml`
- [x] **SEO-04**: `sitemap.xml` lists the catalog index and every game detail page, generated live
      from the database (not a build-time static file)
- [x] **SEO-05**: Every game detail page carries JSON-LD `Game` structured data
- [x] **SEO-06**: The site carries JSON-LD `LocalBusiness` structured data reflecting the club's
      Jujuy location

### Social Sharing

- [x] **SHARE-01**: Every game detail page carries Open Graph tags (title, description, image,
      url, type) reflecting that specific game
- [x] **SHARE-02**: Every game detail page carries Twitter Card tags (`summary_large_image`)
      reflecting that specific game
- [x] **SHARE-03**: OG/Twitter images are properly sized (1200×630) using the game's own cover art
- [x] **SHARE-04**: Pages without a natural hero image (catalog index, About) carry a branded OG
      fallback image (isologo/wordmark)
- [ ] **SHARE-05**: Sharing a game link via the existing native-share control produces an
      appealing, on-brand preview card on the receiving platform (WhatsApp/Facebook/Twitter)
      — server-side markup proven strict-crawler-clean (local + live host); real WhatsApp
      device render still pending human confirmation (01.8-UAT.md Test 4)

### Security Hardening

- [x] **SEC-01**: Session cookies are marked `Secure` in production (env-gated so local HTTP dev
      is unaffected)
- [x] **SEC-02**: HTTPS responses include a valid HSTS header, verified live against production
- [x] **SEC-03**: CSP is reviewed and tightened where possible without breaking the existing
      Google Maps embed (`frame-src`)
- [x] **SEC-04**: CSRF protection is confirmed to also cover LiveView's websocket connect flow
      (not just plain form posts)
- [x] **SEC-05**: JSON-LD script tags render correctly under CSP via a nonce or hash-source — not
      by weakening `script-src` with `unsafe-inline`

### Secrets Audit

- [x] **AUDIT-01**: A full git-history sweep for leaked secrets/keys/credentials/tokens has been
      performed and documented (not just currently-tracked files) (Phase 01.7 plan 04)
- [x] **AUDIT-02**: Any real finding from the sweep is rotated/remediated; false positives
      (e.g. `signing_salt`) are documented and dismissed (Phase 01.7 plan 04)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Sharing & SEO

- **SEO-07**: Google Business Profile setup for the club (out-of-band operational task, not a
  codebase change)

### Security

- **SEC-06**: Automated secret-scanning wired into CI (gitleaks/trufflehog) — user explicitly
  chose a one-time sweep over new ongoing tooling for v1.1
- **SEC-07**: Rate limiting (e.g. Hammer) — no real target yet in this no-auth catalog; arrives
  naturally with Phase 2's magic-link auth

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Server-side composited OG images (cover art + brand overlay) | User chose plain game cover art as `og:image` for v1.1 — simplest, no new image-composition pipeline |
| Ongoing CI secret-scanning | User chose a one-time sweep; repo already keeps real secrets gitignored (D-19) |
| Natural-language search, magic-link auth, favorites | Phase 2 — hero feature, sequenced after this milestone, unchanged in scope |
| Rules Q&A / RAG | Phase 3, unaffected by this milestone |
| Admin/rental tracking | Phase 4, unaffected by this milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEED-01 | Phase 01.7 | Complete |
| SEED-02 | Phase 01.7 | Complete |
| SEO-01 | Phase 01.8 | Complete |
| SEO-02 | Phase 01.8 | Complete |
| SEO-03 | Phase 01.8 | Complete |
| SEO-04 | Phase 01.8 | Complete |
| SEO-05 | Phase 01.8 | Complete |
| SEO-06 | Phase 01.8 | Complete |
| SHARE-01 | Phase 01.8 | Complete |
| SHARE-02 | Phase 01.8 | Complete |
| SHARE-03 | Phase 01.8 | Complete |
| SHARE-04 | Phase 01.8 | Complete |
| SHARE-05 | Phase 01.8 | Pending (01.8-UAT.md Test 4) |
| SEC-01 | Phase 01.7 | Complete |
| SEC-02 | Phase 01.7 | Complete |
| SEC-03 | Phase 01.7 | Complete |
| SEC-04 | Phase 01.7 | Complete |
| SEC-05 | Phase 01.8 | Complete |
| AUDIT-01 | Phase 01.7 | Complete |
| AUDIT-02 | Phase 01.7 | Complete |

**Coverage:**

- v1 requirements: 20 total
- Mapped to phases: 20 (Phase 01.7: 8 · Phase 01.8: 12)
- Unmapped: 0 — 100% coverage, no orphans, no duplicates

**Phase notes:**

- SEC-05 (JSON-LD renders under CSP via nonce/hash-source) is mapped to Phase 01.8, not 01.7: the
  CSP nonce refactor is the first step of the JSON-LD chain and is only observable once JSON-LD
  exists. Phase 01.7's CSP work (SEC-03) is a directive-by-directive review of the existing policy
  and must leave the nonce path open.
- Phase 01.8 depends on Phase 01.7: sharing/Rich-Results verification needs production to already
  hold the real catalog (SEED-01).

---
*Requirements defined: 2026-09-11*
*Last updated: 2026-09-11 after roadmap creation (traceability mapped to Phases 01.7 / 01.8)*
