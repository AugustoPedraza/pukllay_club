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
| `resend._domainkey.pukllay.club` | TXT | `p=MIGf...` (Resend's DKIM public key) | DKIM signing for outbound mail from Resend |
| `send.pukllay.club` | CNAME | `send.forge.rmta.net.` | Resend's MAIL FROM / return-path subdomain — this is where SPF and the bounce-handling MX actually live, **not** the root domain |
| `send.pukllay.club` | TXT (via the CNAME) | `v=spf1 ip4:52.3.252.119 ip4:44.222.39.36 ip4:199.249.231.0/24 ~all` | SPF for the `send` subdomain (Resend's return-path) |
| `send.pukllay.club` | MX (via the CNAME) | `10 feedback.forge.rmta.net.` | Resend's bounce/feedback handling for the `send` subdomain |
| `_dmarc.pukllay.club` | TXT | `v=DMARC1; p=none;` | DMARC policy, monitor-only (`p=none`, no `rua=` reporting address configured) |

The root `pukllay.club` deliberately has **no SPF TXT record of its own** — Resend uses the `send`
subdomain as its MAIL FROM / return-path, so SPF, and the bounce MX, live there instead. This is
correct for Resend's setup, not a gap.

### Transactional email via Resend (phase 01.8.1, plan 03, D-36) — live

Production magic-link and invite emails are sent through Resend (`Swoosh.Adapters.Resend`,
`MAILER_API_KEY`). The domain is verified in the Resend dashboard, the records above are published,
and a sending-only API key is stored as the `MAILER_API_KEY` GitHub secret (set 2026-09-14, never
committed). A production boot without that secret fails by design (`config/runtime.exs`).

Real end-to-end delivery (a magic-link email actually landing in a Gmail inbox) is proven at deploy
time in plan 01.8.1-14, once the whole phase is deployed — this file only tracks that the DNS/account
side is done.

## 3. Verifying

```bash
dig +short NS pukllay.club                       # launch1/launch2.spaceship.net
dig +short A pukllay.club                        # 34.41.63.138
dig +short TXT resend._domainkey.pukllay.club    # Resend's DKIM p=... key
dig +short TXT send.pukllay.club                 # SPF v=spf1 ... (on the send subdomain, not root)
dig +short MX send.pukllay.club                  # 10 feedback.forge.rmta.net.
dig +short TXT _dmarc.pukllay.club                # v=DMARC1; p=none;
gh secret list | grep MAILER_API_KEY             # confirms the secret is set (value never shown)
# Registrar + registration/expiry dates, straight from the .club registry:
curl -s https://rdap.nic.club/domain/pukllay.club \
  | jq '{registrar: [.entities[] | select(.roles|index("registrar")) | .vcardArray[1][] | select(.[0]=="fn") | .[3]], events: .events}'
```

If the production IP ever changes (new VM, released reservation), update the A record in Spaceship
and the table above, then confirm with `dig` before the next `kamal deploy` so TLS issuance succeeds.
