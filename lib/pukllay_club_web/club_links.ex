defmodule PukllayClubWeb.ClubLinks do
  @moduledoc """
  The single source for Pukllay Club's public marketing URLs — the WhatsApp
  group invite, Instagram profile, and linktr.ee hub. These are public,
  non-secret links copied verbatim from `about-page-design-source.html`
  (D-06) and safe to compile straight into the release; every call site
  (header Sumate CTA, footer social icons, About page closing CTA) must
  resolve them through this module rather than holding its own literal
  copy, per SHELL-01's `key_links` contract.

  **Not the reservation number.** The per-game "reserve to play at the
  club" WhatsApp deep-link (plan 01.1-05, D-09/D-10) uses a *different*,
  runtime-config-driven phone number (`RESERVATION_WHATSAPP_NUMBER`
  env var) — that value is operational config, not public marketing copy,
  and must never be resolved through this module.
  """

  @whatsapp_group_url "https://chat.whatsapp.com/L1TLhxGSkgiF1dgkJnp8Pp"
  @instagram_url "https://instagram.com/pukllay_club"
  @linktree_url "https://linktr.ee/PukllayClub"

  @doc "The club's public WhatsApp group invite link (Sumate CTA, footer, About page)."
  def whatsapp_group_url, do: @whatsapp_group_url

  @doc "The club's public Instagram profile."
  def instagram_url, do: @instagram_url

  @doc "The club's linktr.ee hub, referenced from the About page's closing meta line."
  def linktree_url, do: @linktree_url
end
