defmodule PukllayClub.Catalog.Vocabulary do
  @moduledoc """
  The plain-Spanish vocabulary that is the only mechanic/theme/weight-band
  surface the rest of the app sees (CATALOG-05, CATALOG-06). Every string
  here is copied verbatim from `.planning/phases/01-catalog-v1/01-VOCABULARY.md`
  — that file is the user's review surface, so code and document must not
  drift. Edit the doc first, then this module, then re-run its tests.

  Uncovered-term behavior is locked by 01-VOCABULARY.md: a raw BGG
  mechanic/category with no glossary entry here is neither displayed as a
  chip nor offered as a filter facet — `covered_mechanics/1`/`covered_themes/1`
  silently drop it. The raw value still lives in the game's `mechanics`/
  `themes` columns and in `bgg_payload`, so extending this glossary later
  needs no re-seed, only a code change.
  """

  # -- Weight bands (01-VOCABULARY.md section 1) -----------------------------
  #
  # Labels are the club's own verbatim hashtags (D-05); descriptors are
  # Claude-drafted, user-reviewed one-liners. Order is ascending complexity
  # — `weight_bands/0` and the `array_position` sort fragment in
  # `PukllayClub.Catalog` both depend on this exact order.

  @weight_bands [
    %{
      value: "descubre_el_hobby",
      label: "Descubre el hobby",
      descriptor: "Reglas cortas que se explican en 5-10 minutos. Ideal si es tu primera vez."
    },
    %{
      value: "ingenio_estratega",
      label: "Ingenio estratega",
      descriptor: "Reglas de 15-20 minutos y decisiones pensando un par de jugadas por delante."
    },
    %{
      value: "nivel_experto",
      label: "Nivel experto",
      descriptor: "Reglas largas y decisiones profundas. Para mesas con experiencia."
    }
  ]

  # -- Editorial hashtags (D-06, 01-VOCABULARY.md section 4) ------------------
  #
  # Verbatim club strings — never renamed or reframed.

  @editorial_tags [
    %{tag: "#CreaConexiones", meaning: "Reglas simples, familiar / diversión garantizada"},
    %{tag: "#EquipoGanador", meaning: "Cooperativo"},
    %{tag: "#DuelosMemorables", meaning: "Solo 2 jugadores"}
  ]

  # -- Mechanic glossary (35 terms, 01-VOCABULARY.md section 3a) --------------
  #
  # The last 10 entries (Area Movement .. Trading) were added during 01-06's
  # reconciliation pass against priv/repo/seed_data/catalog_seed_report.md's
  # real "uncovered mechanic terms" list — every uncovered term occurring on
  # 8+ seeded games was either added here or recorded in 01-VOCABULARY.md's
  # "Consciously uncovered" subsection, never silently dropped.

  @mechanics %{
    "Set Collection" => "Colecciona sets",
    "Hand Management" => "Gestión de mano",
    "Open Drafting" => "Elige y pasa",
    "End Game Bonuses" => "Bonus finales",
    "Solo / Solitaire Game" => "Modo solitario",
    "Tile Placement" => "Coloca losetas",
    "Variable Set-up" => "Partida distinta",
    "Dice Rolling" => "Tira dados",
    "Variable Player Powers" => "Poderes únicos",
    "Worker Placement" => "Coloca trabajadores",
    "Contracts" => "Cumple encargos",
    "Area Majority / Influence" => "Domina zonas",
    "Cooperative Game" => "Juego cooperativo",
    "Modular Board" => "Tablero variable",
    "Take That" => "Ataques directos",
    "Push Your Luck" => "Tienta la suerte",
    "Pattern Building" => "Forma patrones",
    "Race" => "Carrera",
    "Deck, Bag, and Pool Building" => "Construye tu mazo",
    "Simultaneous Action Selection" => "Todos a la vez",
    "Grid Movement" => "Movimiento en casillas",
    "Auction / Bidding" => "Subastas",
    "Memory" => "Memoria",
    "Real-Time" => "Contrarreloj",
    "Deduction" => "Deducción",
    "Area Movement" => "Movimiento por áreas",
    "Voting" => "Votación",
    "Action Drafting" => "Selecciona acciones",
    "Player Elimination" => "Eliminación de jugadores",
    "Role Playing" => "Interpretación de rol",
    "Hidden Roles" => "Roles ocultos",
    "Pick-up and Deliver" => "Recoge y entrega",
    "Storytelling" => "Narra historias",
    "Simulation" => "Simulación",
    "Trading" => "Comercia"
  }

  # -- Theme/category glossary (32 terms, 01-VOCABULARY.md section 3b) -------
  #
  # The last 10 entries (Exploration .. Travel) were added during the same
  # 01-06 reconciliation pass, from the seed report's "uncovered category
  # terms" list.

  @themes %{
    "Card Game" => "Juego de cartas",
    "Party Game" => "Juego de fiesta",
    "Fantasy" => "Fantasía",
    "Science Fiction" => "Ciencia ficción",
    "Animals" => "Animales",
    "Economic" => "Economía",
    "Adventure" => "Aventura",
    "Medieval" => "Medieval",
    "Ancient" => "Mundo antiguo",
    "Nautical" => "Náutico",
    "Farming" => "Granja",
    "City Building" => "Construye ciudades",
    "Deduction" => "Deducción",
    "Horror" => "Terror",
    "Miniatures" => "Miniaturas",
    "Puzzle" => "Rompecabezas",
    "Racing" => "Carreras",
    "Space Exploration" => "Exploración espacial",
    "Trains" => "Trenes",
    "Wargame" => "Bélico",
    "Word Game" => "Juego de palabras",
    "Children's Game" => "Para peques",
    "Exploration" => "Exploración",
    "Bluffing" => "Farol",
    "Civilization" => "Civilización",
    "Negotiation" => "Negociación",
    "Pirates" => "Piratas",
    "Fighting" => "Combate",
    "Abstract Strategy" => "Estrategia abstracta",
    "Humor" => "Humor",
    "Mythology" => "Mitología",
    "Travel" => "Viajes"
  }

  @doc "Returns the three weight bands, ascending, each with `:value`, `:label`, `:descriptor`."
  def weight_bands, do: @weight_bands

  @doc "Returns the band map for a DB `weight_band` value, or `nil` if unknown."
  def weight_band(value), do: Enum.find(@weight_bands, &(&1.value == value))

  @doc """
  Returns the 1-based difficulty level (1..3) for a DB `weight_band` value, or
  `nil` for an unknown/nil value. This is the only difficulty source in the
  app — derived from `@weight_bands`' own order via `Enum.find_index/2` so it
  can never disagree with `weight_bands/0` or the `array_position` sort
  fragment in `PukllayClub.Catalog`. Not a second Fácil/Moderado/Difícil
  scale — it reuses the club's existing three-band vocabulary.
  """
  def weight_band_level(value) do
    case Enum.find_index(@weight_bands, &(&1.value == value)) do
      nil -> nil
      index -> index + 1
    end
  end

  @doc "Returns the 3 editorial hashtags, each with `:tag` (verbatim) and `:meaning`."
  def editorial_tags, do: @editorial_tags

  @doc "Returns the Spanish chip label for a covered BGG mechanic, or `nil` if uncovered."
  def mechanic_label(raw), do: Map.get(@mechanics, raw)

  @doc "Returns the Spanish chip label for a covered BGG category, or `nil` if uncovered."
  def theme_label(raw), do: Map.get(@themes, raw)

  @doc "Maps a Spanish chip label back to the raw BGG mechanic values it covers."
  def mechanic_terms_for(label), do: terms_for(@mechanics, label)

  @doc "Maps a Spanish chip label back to the raw BGG category values it covers."
  def theme_terms_for(label), do: terms_for(@themes, label)

  @doc "Filters a game's raw mechanic list down to covered Spanish labels, dropping the rest."
  def covered_mechanics(raw_mechanics) when is_list(raw_mechanics), do: covered(@mechanics, raw_mechanics)

  @doc "Filters a game's raw theme list down to covered Spanish labels, dropping the rest."
  def covered_themes(raw_themes) when is_list(raw_themes), do: covered(@themes, raw_themes)

  @doc "Sorted, distinct Spanish mechanic labels — the filter drawer's mechanic pill options."
  def mechanic_options, do: options(@mechanics)

  @doc "Sorted, distinct Spanish theme labels — the filter drawer's theme pill options."
  def theme_options, do: options(@themes)

  defp terms_for(glossary, label) do
    for {raw, l} <- glossary, l == label, do: raw
  end

  defp covered(glossary, raw_values) do
    raw_values
    |> Enum.map(&Map.get(glossary, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp options(glossary) do
    glossary
    |> Map.values()
    |> Enum.uniq()
    |> Enum.sort()
  end
end
