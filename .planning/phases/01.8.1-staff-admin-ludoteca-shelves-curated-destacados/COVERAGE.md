# API Coverage — transactional email provider (D-36), BGG XML API2, Cloudflare R2, Gemini

> Full coverage by default. Opt-outs are explicit, reasoned decisions.
> The email provider is the one new integration (chosen at plan 03's checkpoint: Resend, Brevo or
> Postmark, all behind the same Swoosh adapter seam). BGG, R2 and Gemini are existing
> integrations (`Catalog.Seed.*`) that this phase runs in production for the first time (D-02).

| capability | decision | reason |
|---|---|---|
| email.send_transactional | INTEGRATE | |
| email.domain_authentication_dkim_spf | INTEGRATE | |
| email.batch_send | OPT-OUT | not needed — at most one magic-link or invite email per action, ≤4 staff |
| email.templates_hosted | OPT-OUT | not needed — bodies are rendered by `UserNotifier` in the app |
| email.scheduled_send | OPT-OUT | not needed — login and invite links must send immediately |
| email.webhooks_delivery_events | OPT-OUT | not needed yet — delivery is verified manually in plan 14; revisit if staff report missing links |
| email.contacts_audiences | OPT-OUT | explicitly out of scope — no marketing email |
| email.domains_management_api | OPT-OUT | not needed — the domain is verified once by hand in the provider dashboard (plan 03 Task 3) |
| email.inbound_parsing | OPT-OUT | explicitly out of scope — the app never receives email |
| bgg.thing_by_id | INTEGRATE | |
| bgg.thing_versions_for_spanish_cover | INTEGRATE | |
| bgg.thing_stats_weight_rating_rank | INTEGRATE | |
| bgg.search | OPT-OUT | not needed — staff paste a BGG ID or URL (D-01), no name search |
| bgg.collection | OPT-OUT | explicitly out of scope — the club catalog lives in this database, not a BGG collection |
| bgg.plays_forum_hot | OPT-OUT | explicitly out of scope — no play logging or community data |
| r2.put_object | INTEGRATE | |
| r2.list_objects | OPT-OUT | not needed in production — only the offline og-card backfill verification uses it |
| r2.delete_object | OPT-OUT | not needed yet — retiring a game is a soft delete (D-08) and keeps its images |
| gemini.generate_content_structured_translation | INTEGRATE | |
| gemini.other_generation_embeddings | OPT-OUT | explicitly out of scope — natural-language search and embeddings are Phase 2 |
