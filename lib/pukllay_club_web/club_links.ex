defmodule PukllayClubWeb.ClubLinks do
  @moduledoc """
  The single source for Pukllay Club's public marketing URLs — the WhatsApp
  group invite, Instagram profile, Facebook page, and contact email. These
  are public, non-secret links safe to compile straight into the release;
  every call site (header Sumate CTA, footer social icons, About page
  closing CTA) must resolve them through this module rather than holding
  its own literal copy, per SHELL-01's `key_links` contract.

  `whatsapp_group_url/0` and `instagram_url/0` are copied verbatim from
  `about-page-design-source.html` (D-06). `facebook_url/0` and
  `contact_email/0` were added in plan 01.1-01 Task 3, per the developer's
  explicit post-Task-1 revision of the footer's social-icon set (Task 2
  checkpoint answer (b) superseding the plan's original menu): the footer
  renders exactly four channels — WhatsApp, Facebook, Instagram, Email —
  not the originally-planned WhatsApp/Instagram/linktr.ee set.
  `linktree_url/0` was removed in that same revision: it shipped in Task 1
  but the linktr.ee channel is no longer rendered anywhere, per the
  developer's explicit "remove it" instruction.

  `maps_url/0` was added in plan 01.4-02 (D-06): the club's real Google Maps
  venue location link, resolved by the About page's rebuilt Contacto card
  map thumbnail — same public-URL, single-source-of-truth contract as every
  other function here.

  `maps_embed_url/0` and `maps_embed_origin/0` were added in plan 01.4-12
  (G-01.4-5, D-11/D-12), superseding the static Maps screenshot the Contacto
  card shipped with. `maps_embed_url/0` is the keyless "Share > Embed" form
  of the club's pinned location — copied byte for byte from the Google Maps
  UI's own export, requiring no Google Cloud API key, no enabled billing
  account, and deliberately NOT the Maps Embed API (`/maps/embed/v1/place?
  key=...`) or the Maps JavaScript API, both of which need both. Its `pb=`
  payload is undocumented and unsupported by Google: it can change or stop
  resolving with no build failure and no test failure, and
  `test/visual/about_map_attribution.mjs` — which gates the child frame's
  actual navigation commit in a real browser — is the only detector this
  repo has for that. `maps_embed_origin/0` is derived from
  `maps_embed_url/0` at compile time (never typed as a second literal) and
  exists solely to feed `PukllayClubWeb.CSP.policy/0`'s `frame-src`
  directive, so that directive can never name a host the iframe does not
  actually load.

  **Not the reservation number.** The per-game "reserve to play at the
  club" WhatsApp deep-link (plan 01.1-05, D-09/D-10) uses a *different*,
  runtime-config-driven phone number (`RESERVATION_WHATSAPP_NUMBER`
  env var) — that value is operational config, not public marketing copy,
  and must never be resolved through this module.
  """

  @whatsapp_group_url "https://chat.whatsapp.com/L1TLhxGSkgiF1dgkJnp8Pp"
  @instagram_url "https://instagram.com/pukllay_club"
  @facebook_url "https://www.facebook.com/pukllayclub/"
  @contact_email "pukllay.club@gmail.com"
  @maps_url "https://maps.app.goo.gl/1GEBqjPDUnVkj68B6"
  @maps_embed_url "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3639.6166670771295!2d-65.31692332474148!3d-24.18385368475632!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x941b0f37e482f525%3A0xec531e2a26316237!2sCLUB%20DE%20EMPRENDEDORES%20DE%20JUJUY!5e0!3m2!1sen!2sar!4v1788656261124!5m2!1sen!2sar"
  @maps_embed_uri URI.new!(@maps_embed_url)
  @maps_embed_origin "#{@maps_embed_uri.scheme}://#{@maps_embed_uri.host}"

  @doc "The club's public WhatsApp group invite link (Sumate CTA, footer, About page)."
  def whatsapp_group_url, do: @whatsapp_group_url

  @doc "The club's public Instagram profile."
  def instagram_url, do: @instagram_url

  @doc "The club's public Facebook page (footer social icon)."
  def facebook_url, do: @facebook_url

  @doc "The club's public contact email address (footer social icon, rendered as a mailto: link)."
  def contact_email, do: @contact_email

  @doc "The club's Google Maps location link (About page Contacto card map thumbnail, D-06)."
  def maps_url, do: @maps_url

  @doc """
  The keyless Google Maps embed `src` for the club's pinned location
  (About page Contacto card, plan 01.4-12, D-11). See the moduledoc for
  why this is the "Share > Embed" form rather than the Maps Embed API.
  """
  def maps_embed_url, do: @maps_embed_url

  @doc """
  The scheme-and-host of `maps_embed_url/0`, derived at compile time —
  never a second literal. Feeds `PukllayClubWeb.CSP.policy/0`'s
  `frame-src` directive (D-12).
  """
  def maps_embed_origin, do: @maps_embed_origin
end
