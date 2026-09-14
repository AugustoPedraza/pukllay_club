# Runbook: `pukllay.club` domain and DNS

Where the domain lives, what records it has, and how to change or verify them. DNS is **outside
git**: nothing in this repo manages it, so this file is the only record of it.

## 1. Registrar and DNS host

| Item | Value |
|------|-------|
| Registrar | **Spaceship, Inc.** — https://www.spaceship.com (log in, then Launchpad → Domain Manager) |
| DNS host | Spaceship (same account) — nameservers `launch1.spaceship.net`, `launch2.spaceship.net` |
| Registered | 2026-07-24 |
| **Expires** | **2027-07-24** — confirm auto-renew is on in Spaceship before then; an expired domain takes the site, TLS renewal and email down together |

Registrar, dates and nameservers were confirmed from the `.club` registry RDAP record on 2026-09-14
(see §3). The Spaceship account's login email is not recorded here on purpose.

## 2. Records

| Name | Type | Value | Purpose |
|------|------|-------|---------|
| `pukllay.club` | A | `34.41.63.138` | GCP e2-micro reserved external IP; kamal-proxy terminates TLS there (Let's Encrypt HTTP-01, so the A record must keep pointing at the host) |

As of 2026-09-14 there are **no MX or TXT records** — so no SPF, DKIM or DMARC yet, and the domain
receives no email.

### Pending: transactional email via Resend (phase 01.8.1, plan 03, D-36)

Production magic-link and invite emails are sent through Resend (`Swoosh.Adapters.Resend`,
`MAILER_API_KEY`). Before the domain can send, add in Spaceship's DNS editor exactly what Resend's
domain page shows for `pukllay.club`:

- **SPF** — a TXT record with Resend's `include:`. A domain may have only **one** SPF record: if one
  exists by then, merge the `include:` into it instead of adding a second.
- **DKIM** — the TXT/CNAME host and value Resend shows.
- **DMARC** — TXT at `_dmarc.pukllay.club`: `v=DMARC1; p=none; rua=mailto:<an inbox you read>`.

Then wait for Resend to show the domain verified, create a sending-only API key, and store it with
`gh secret set MAILER_API_KEY` (paste at the prompt; never commit it). A production boot without that
secret fails by design. Once done, update the table above with the real records.

## 3. Verifying

```bash
dig +short NS pukllay.club           # launch1/launch2.spaceship.net
dig +short A pukllay.club            # 34.41.63.138
dig +short TXT pukllay.club          # SPF v=spf1 ... (after the Resend step)
dig +short TXT _dmarc.pukllay.club   # v=DMARC1 ... (after the Resend step)
# Registrar + registration/expiry dates, straight from the .club registry:
curl -s https://rdap.nic.club/domain/pukllay.club \
  | jq '{registrar: [.entities[] | select(.roles|index("registrar")) | .vcardArray[1][] | select(.[0]=="fn") | .[3]], events: .events}'
```

If the production IP ever changes (new VM, released reservation), update the A record in Spaceship
and the table above, then confirm with `dig` before the next `kamal deploy` so TLS issuance succeeds.
