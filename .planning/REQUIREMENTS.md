# Requirements: PukllayClub

**Defined:** 2026-09-11
**Core Value:** A member can describe what they want in plain Spanish and find a game that fits —
even without already knowing board-game vocabulary.

## v1 Requirements

Requirements for milestone v1.1 "Sharable Version". Each maps to roadmap phases.

### Production Data

- [ ] **SEED-01**: Production's live database has the full game catalog (~400+ games) loaded,
      matching dev — currently empty
- [ ] **SEED-02**: A safe, repeatable, documented path exists to (re-)run the seed pipeline against
      production

### SEO

- [ ] **SEO-01**: Every game detail page has a unique, real meta description
- [ ] **SEO-02**: Catalog card and hover-preview images have real, descriptive `alt` text
      (currently `alt=""`)
- [ ] **SEO-03**: `robots.txt` allows crawling and references `sitemap.xml`
- [ ] **SEO-04**: `sitemap.xml` lists the catalog index and every game detail page, generated live
      from the database (not a build-time static file)
- [ ] **SEO-05**: Every game detail page carries JSON-LD `Game` structured data
- [ ] **SEO-06**: The site carries JSON-LD `LocalBusiness` structured data reflecting the club's
      Jujuy location

### Social Sharing

- [ ] **SHARE-01**: Every game detail page carries Open Graph tags (title, description, image,
      url, type) reflecting that specific game
- [ ] **SHARE-02**: Every game detail page carries Twitter Card tags (`summary_large_image`)
      reflecting that specific game
- [ ] **SHARE-03**: OG/Twitter images are properly sized (1200×630) using the game's own cover art
- [ ] **SHARE-04**: Pages without a natural hero image (catalog index, About) carry a branded OG
      fallback image (isologo/wordmark)
- [ ] **SHARE-05**: Sharing a game link via the existing native-share control produces an
      appealing, on-brand preview card on the receiving platform (WhatsApp/Facebook/Twitter)

### Security Hardening

- [ ] **SEC-01**: Session cookies are marked `Secure` in production (env-gated so local HTTP dev
      is unaffected)
- [ ] **SEC-02**: HTTPS responses include a valid HSTS header, verified live against production
- [ ] **SEC-03**: CSP is reviewed and tightened where possible without breaking the existing
      Google Maps embed (`frame-src`)
- [ ] **SEC-04**: CSRF protection is confirmed to also cover LiveView's websocket connect flow
      (not just plain form posts)
- [ ] **SEC-05**: JSON-LD script tags render correctly under CSP via a nonce or hash-source — not
      by weakening `script-src` with `unsafe-inline`

### Secrets Audit

- [ ] **AUDIT-01**: A full git-history sweep for leaked secrets/keys/credentials/tokens has been
      performed and documented (not just currently-tracked files)
- [ ] **AUDIT-02**: Any real finding from the sweep is rotated/remediated; false positives
      (e.g. `signing_salt`) are documented and dismissed

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
| SEED-01 | TBD | Pending |
| SEED-02 | TBD | Pending |
| SEO-01 | TBD | Pending |
| SEO-02 | TBD | Pending |
| SEO-03 | TBD | Pending |
| SEO-04 | TBD | Pending |
| SEO-05 | TBD | Pending |
| SEO-06 | TBD | Pending |
| SHARE-01 | TBD | Pending |
| SHARE-02 | TBD | Pending |
| SHARE-03 | TBD | Pending |
| SHARE-04 | TBD | Pending |
| SHARE-05 | TBD | Pending |
| SEC-01 | TBD | Pending |
| SEC-02 | TBD | Pending |
| SEC-03 | TBD | Pending |
| SEC-04 | TBD | Pending |
| SEC-05 | TBD | Pending |
| AUDIT-01 | TBD | Pending |
| AUDIT-02 | TBD | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 0 (pending roadmap creation)
- Unmapped: 20 ⚠️ (resolved by gsd-roadmapper next)

---
*Requirements defined: 2026-09-11*
*Last updated: 2026-09-11 after initial definition*
