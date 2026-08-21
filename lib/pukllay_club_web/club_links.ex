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

  @doc "The club's public WhatsApp group invite link (Sumate CTA, footer, About page)."
  def whatsapp_group_url, do: @whatsapp_group_url

  @doc "The club's public Instagram profile."
  def instagram_url, do: @instagram_url

  @doc "The club's public Facebook page (footer social icon)."
  def facebook_url, do: @facebook_url

  @doc "The club's public contact email address (footer social icon, rendered as a mailto: link)."
  def contact_email, do: @contact_email
end
