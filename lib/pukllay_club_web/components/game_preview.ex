defmodule PukllayClubWeb.GamePreview do
  @moduledoc """
  Shared markup for the two surfaces that reveal a card's secondary
  metadata (sketch 002, variant D): the desktop hover-intent preview,
  rendered through a `position: fixed` portal outside every scrolling
  rail, and the mobile full-screen sheet. Both surfaces clone the exact
  same server-rendered `preview_body/1` markup and consume the same `pk-*`
  CSS classes verbatim — this is the structural defence against the two
  surfaces drifting apart in font-size, line-clamp, or aspect-ratio, which
  is exactly what happened during sketching (see
  `.claude/skills/sketch-findings-pukllay_club/references/card-interaction.md`).

  `PukllayClubWeb.GameCard` embeds `preview_template/1` once per card;
  `preview_host/1` is rendered exactly once, outside every rail, by
  `PukllayClubWeb.CatalogLive.Index`. The `.GamePreview` colocated hook
  clones the triggering card's `<template>` content into the portal (desktop
  hover) or the sheet (touch tap) via `replaceChildren` — it never
  assembles markup from strings or from `dataset` values, which is the
  threat-model mitigation for T-01-31.
  """
  use PukllayClubWeb, :html

  alias PukllayClub.Catalog.Vocabulary

  @doc """
  Three dots, the first `level` of them filled, indicating a game's
  difficulty (1..3, from `Vocabulary.weight_band_level/1`). Filled dots are
  a muted neutral colour, deliberately not the brand accent, so the
  indicator reads as a metadata detail rather than a standalone badge.
  """
  attr :level, :integer, required: true

  def difficulty_indicator(assigns) do
    ~H"""
    <span class="pk-difficulty">
      <span :for={n <- 1..3} class={["pk-difficulty-dot", n <= @level && "is-filled"]}></span>
    </span>
    """
  end

  @doc """
  Players / tiempo / dificultad, in that fixed order, `justify-content:
  space-between` across up to three `pk-fact` pills. Each fact is omitted
  independently when its underlying data is absent — see the field-level
  rules in the moduledoc-referenced sketch findings.
  """
  attr :game, PukllayClub.Catalog.Game, required: true

  def facts_row(assigns) do
    assigns =
      assigns
      |> assign(:players_text, players_text(assigns.game))
      |> assign(:tiempo_text, tiempo_text(assigns.game))
      |> assign(:band, Vocabulary.weight_band(assigns.game.weight_band))
      |> assign(:level, Vocabulary.weight_band_level(assigns.game.weight_band))

    ~H"""
    <div class="pk-facts-row">
      <span :if={@players_text} class="pk-fact">
        <.icon name="hero-users-micro" class="size-3" />{@players_text}
      </span>
      <span :if={@tiempo_text} class="pk-fact">
        <.icon name="hero-clock-micro" class="size-3" />{@tiempo_text}
      </span>
      <span :if={@band} class="pk-fact">
        <.difficulty_indicator level={@level} />{@band.label}
      </span>
    </div>
    """
  end

  @doc """
  The one shared body both the desktop portal and the mobile sheet clone
  verbatim: poster, facts row, title, description, the single sheet-only
  editorial tag (hidden on the portal by one CSS rule), and the outlined
  `Ver detalles` CTA — a lower-commitment action than the interaction that
  revealed it, so it is never the filled primary button.
  """
  attr :game, PukllayClub.Catalog.Game, required: true

  def preview_body(assigns) do
    assigns = assign(assigns, :cover, assigns.game.cover_url || assigns.game.thumbnail_url)

    ~H"""
    <figure class="pk-preview-poster bg-base-300">
      <img :if={@cover} src={@cover} alt="" class="h-full w-full object-cover js-cover-fallback" />
      <div
        :if={@cover}
        class="hidden h-full w-full items-center justify-center bg-base-300 text-primary"
      >
        <.icon name="hero-puzzle-piece" class="size-12" />
      </div>
      <div
        :if={!@cover}
        class="flex h-full w-full items-center justify-center bg-base-300 text-primary"
      >
        <.icon name="hero-puzzle-piece" class="size-12" />
      </div>
    </figure>
    <div class="pk-preview-body">
      <.facts_row game={@game} />
      <p class="pk-preview-title">{@game.name}</p>
      <p class="pk-preview-text">{@game.description}</p>
      <span
        :if={@game.tags != []}
        data-sheet-only
        class="badge badge-sm badge-accent"
      >
        {List.first(@game.tags)}
      </span>
      <.link
        navigate={~p"/juegos/#{@game}"}
        class="pk-preview-cta btn btn-outline btn-primary btn-block min-h-11"
      >
        Ver detalles
      </.link>
    </div>
    """
  end

  @doc """
  Wraps `preview_body/1` in an inert `<template>` — not a hidden `div` —
  so browsers never fetch each card's cover image at page load; the hook
  clones this content on demand when a card is hovered or tapped.
  """
  attr :game, PukllayClub.Catalog.Game, required: true

  def preview_template(assigns) do
    ~H"""
    <template data-game-preview>
      <.preview_body game={@game} />
    </template>
    """
  end

  @doc """
  Renders the shared preview surfaces exactly once, outside every
  scrolling rail. `phx-update="ignore"` on the portal is load-bearing:
  the `.GamePreview` hook writes cloned nodes into it directly, and
  LiveView must never patch them away.
  """
  def preview_host(assigns) do
    ~H"""
    <div
      id="game-preview"
      phx-hook=".GamePreview"
      data-hover-delay="300"
      data-hide-delay="120"
      data-portal-width="360"
      data-edge-gap="8"
      data-top-gap="16"
    >
      <script :type={Phoenix.LiveView.ColocatedHook} name=".GamePreview">
        export default {
          mounted() {
            this.portal = this.el.querySelector("#game-preview-portal")
            this.hoverDelay = parseInt(this.el.dataset.hoverDelay, 10)
            this.hideDelay = parseInt(this.el.dataset.hideDelay, 10)
            this.portalWidth = parseInt(this.el.dataset.portalWidth, 10)
            this.edgeGap = parseInt(this.el.dataset.edgeGap, 10)
            this.topGap = parseInt(this.el.dataset.topGap, 10)
            this.finePointer = window.matchMedia("(hover: hover) and (pointer: fine)").matches
            this.showTimer = null
            this.hideTimer = null

            this.onMouseOver = (event) => {
              if (!this.finePointer) return
              const card = event.target.closest("[data-game-card]")
              if (!card) return
              if (event.relatedTarget && card.contains(event.relatedTarget)) return
              clearTimeout(this.hideTimer)
              clearTimeout(this.showTimer)
              this.showTimer = setTimeout(() => this.showPortal(card), this.hoverDelay)
            }
            document.addEventListener("mouseover", this.onMouseOver)

            this.onMouseOut = (event) => {
              if (!this.finePointer) return
              const card = event.target.closest("[data-game-card]")
              if (!card) return
              if (event.relatedTarget && card.contains(event.relatedTarget)) return
              clearTimeout(this.showTimer)
              this.hideTimer = setTimeout(() => this.hidePortal(), this.hideDelay)
            }
            document.addEventListener("mouseout", this.onMouseOut)

            this.onPortalEnter = () => clearTimeout(this.hideTimer)
            this.onPortalLeave = () => {
              this.hideTimer = setTimeout(() => this.hidePortal(), this.hideDelay)
            }
            this.portal.addEventListener("mouseenter", this.onPortalEnter)
            this.portal.addEventListener("mouseleave", this.onPortalLeave)

            this.onScroll = () => this.hidePortal()
            window.addEventListener("scroll", this.onScroll, {capture: true, passive: true})

            this.onKeydown = (event) => {
              if (event.key === "Escape") this.hidePortal()
            }
            document.addEventListener("keydown", this.onKeydown)
          },

          showPortal(card) {
            const rect = card.getBoundingClientRect()
            const grow = this.portalWidth - rect.width
            const left = Math.max(
              this.edgeGap,
              Math.min(rect.left - grow / 2, window.innerWidth - this.portalWidth - this.edgeGap)
            )
            const top = Math.max(this.topGap, rect.top - grow / 2)

            this.portal.style.width = `${this.portalWidth}px`
            this.portal.style.left = `${left}px`
            this.portal.style.top = `${top}px`

            const template = card.querySelector("template[data-game-preview]")
            if (!template) return
            this.portal.replaceChildren(template.content.cloneNode(true))
            this.portal.classList.add("is-visible")
          },

          hidePortal() {
            this.portal.classList.remove("is-visible")
          },

          destroyed() {
            clearTimeout(this.showTimer)
            clearTimeout(this.hideTimer)
            document.removeEventListener("mouseover", this.onMouseOver)
            document.removeEventListener("mouseout", this.onMouseOut)
            window.removeEventListener("scroll", this.onScroll, {capture: true})
            document.removeEventListener("keydown", this.onKeydown)
          }
        }
      </script>
      <div id="game-preview-portal" class="pk-portal" phx-update="ignore" aria-hidden="true"></div>
    </div>
    """
  end

  defp players_text(%{min_players: nil}), do: nil

  defp players_text(%{min_players: min, max_players: max}) when is_nil(max) or min == max,
    do: "#{min}"

  defp players_text(%{min_players: min, max_players: max}), do: "#{min}-#{max}"

  defp tiempo_text(%{min_playtime: nil, max_playtime: nil, playing_time: nil}), do: nil
  defp tiempo_text(%{min_playtime: nil, max_playtime: nil, playing_time: pt}), do: "#{pt} min"

  defp tiempo_text(%{min_playtime: min, max_playtime: max}) when is_nil(max) or min == max,
    do: "#{min} min"

  defp tiempo_text(%{min_playtime: min, max_playtime: max}), do: "#{min}-#{max} min"
end
