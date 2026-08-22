defmodule PukllayClubWeb.AboutLive do
  @moduledoc """
  The club's About/landing page (SHELL-01/02).

  Reachable at two URL aliases pointing at this same LiveView — `/club`
  and `/quienes-somos` (D-01) — both must resolve identically; neither
  route redirects to the other. This plan (01.1-01) ships the hero
  section only; the photo carousel, "Qué hacemos"/"Nuestra historia"
  band, FAQ band, and closing CTA band (D-07) land in plan 01.1-02.

  Content is the user-supplied real copy from `about-page-design-source.html`
  (D-06), used verbatim. The club model is play-at-the-club-only (D-09):
  members come play on Saturdays at a physical venue, the club brings the
  games — this page never describes borrowing or taking games home
  (D-09, prohibitions).

  Renders inside the shared `Layouts.app` shell with the "Quiénes Somos"
  nav-links state (page-shell.md: About is a sibling top-level page, not
  a drill-down, so it gets the same nav-links row Inicio has with
  "Quiénes Somos" marked active — never a breadcrumb, per D-07/page-shell.md).
  """
  use PukllayClubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Quiénes somos")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullbleed sticky active_nav={:quienes_somos}>
      <:nav_links>
        <.link navigate={~p"/"}>Inicio</.link>
        <.link navigate={~p"/quienes-somos"} aria-current="page">Quiénes Somos</.link>
      </:nav_links>

      <div class="mx-auto w-full max-w-7xl pk-gutter space-y-6">
        <section class="space-y-3 py-12 text-center">
          <p class="font-sans text-xs uppercase tracking-widest text-neutral">
            Club de juegos de mesa · Jujuy
          </p>
          <h1 class="font-display text-5xl">Conectá jugando</h1>
          <p class="font-sans text-base text-neutral">
            Nos juntamos todos los sábados a jugar. Venís, te sentás, alguien te explica.
          </p>
          <div class="flex justify-center">
            <Layouts.sumate_cta />
          </div>
        </section>
      </div>

      <%!-- About-scoped mobile sticky join-CTA bar (01.1-09, D-05 superseded).
      Page-owned, not shell-owned: no other route can accidentally inherit it,
      which is the whole point of the D-05 supersession — a site-wide sticky
      bar would put the join ask back on every page the header just stopped
      putting it on. Reuses the hero's own sumate_cta/1 so the two placements
      can never drift to different labels/destinations. Both elements are
      display:none at base, turned on only in the trailing @media (max-width:
      480px) block. --%>
      <div class="pk-about-cta-spacer" aria-hidden="true"></div>
      <div class="pk-about-cta-bar"><Layouts.sumate_cta class="w-full" /></div>
    </Layouts.app>
    """
  end
end
