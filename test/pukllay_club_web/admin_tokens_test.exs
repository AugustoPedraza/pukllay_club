defmodule PukllayClubWeb.AdminTokensTest do
  # Guards assets/css/admin/tokens.css (D-33, D-34, D-19o) against silent
  # drift away from the values `01.8.2-TOKENS.md` recorded as the
  # reconciliation authority. Follows stylesheet_integrity_test.exs's
  # file-read-and-assert convention: read the real files off disk, never
  # trust a comment — every assertion below strips comments first so a
  # comment merely MENTIONING a token or a discarded property can never
  # satisfy (or defeat) its own guard.
  use ExUnit.Case, async: true

  @tokens_path Path.expand("../../assets/css/admin/tokens.css", __DIR__)
  @app_css_path Path.expand("../../assets/css/app.css", __DIR__)

  @land_tokens ~w(--val --color-surface --color-surface-2 --stroke)

  defp tokens_source, do: File.read!(@tokens_path)
  defp app_css_source, do: File.read!(@app_css_path)

  # Block comments in this codebase are NOT written with a leading `*` per
  # continuation line (see app.css's own CASCADE-LAYER HAZARD comment), so a
  # line-anchored `^\s*\*` filter (stylesheet_integrity_test.exs's own
  # comment-scanner) would not catch a comment's continuation lines here.
  # Strip the whole `/* ... */` span instead — non-greedy, dot matches
  # newline (`s` modifier), matching how a CSS tokenizer actually consumes a
  # comment.
  defp strip_comments(src), do: Regex.replace(~r/\/\*.*?\*\//s, src, "")

  # The FIRST `:root[data-theme="THEME"] { ... }` block in `src`. Task 2
  # declares exactly one such block per theme in tokens.css, with no nested
  # braces inside — a non-greedy `[^}]*` body match is therefore safe.
  defp theme_block(src, theme) do
    case Regex.run(~r/:root\[data-theme="#{theme}"\]\s*\{([^}]*)\}/s, src) do
      [_, body] -> body
      nil -> nil
    end
  end

  # app.css's shared `--pk-ramp-*` palette, as a stop-number => hex map.
  # Located by CONTENT (a `:root { ... }` block that declares `--pk-ramp-50`)
  # rather than by position, since app.css has more than one `:root { }`
  # block and position is not a stable anchor.
  defp ramp_map do
    src = strip_comments(app_css_source())

    [_, body] = Regex.run(~r/:root\s*\{([^}]*--pk-ramp-50:[^}]*)\}/s, src)

    ~r/--pk-ramp-(\d+):\s*(#[0-9A-Fa-f]{6})/
    |> Regex.scan(body)
    |> Map.new(fn [_, stop, hex] -> {stop, String.upcase(hex)} end)
  end

  # app.css's `@plugin "daisyui/packages/bundle/daisyui-theme" { name: "THEME"; ... }`
  # block body, for either "dark" or "light".
  defp daisyui_theme_block(src, theme) do
    ~r/@plugin\s+"daisyui\/packages\/bundle\/daisyui-theme"\s*\{([^}]*)\}/s
    |> Regex.scan(src)
    |> Enum.map(fn [_, body] -> body end)
    |> Enum.find(fn body -> body =~ ~r/name:\s*"#{theme}"/ end)
  end

  # Resolves a raw CSS custom-property value: either `var(--pk-ramp-NNN)`
  # (looked up against `ramp`) or a literal hex, already normalised to
  # upper-case 6-digit form by the caller's regex where relevant.
  defp resolve(raw, ramp) do
    case Regex.run(~r/var\(--pk-ramp-(\d+)\)/, raw) do
      [_, stop] -> Map.fetch!(ramp, stop)
      nil -> raw |> String.trim() |> String.upcase()
    end
  end

  defp declared_value(block, token) do
    [_, raw] = Regex.run(~r/#{Regex.escape(token)}\s*:\s*([^;]+);/, block)
    String.trim(raw)
  end

  test "the dark theme block declares every LAND token from 01.8.2-TOKENS.md" do
    block = tokens_source() |> strip_comments() |> theme_block("dark")

    assert block, "No :root[data-theme=\"dark\"] block found in assets/css/admin/tokens.css."

    for token <- @land_tokens do
      assert block =~ ~r/#{Regex.escape(token)}\s*:/,
             "Expected `#{token}:` inside the [data-theme=\"dark\"] block of " <>
               "assets/css/admin/tokens.css, per 01.8.2-TOKENS.md's LAND set."
    end
  end

  test "the light theme block declares every LAND token from 01.8.2-TOKENS.md" do
    block = tokens_source() |> strip_comments() |> theme_block("light")

    assert block, "No :root[data-theme=\"light\"] block found in assets/css/admin/tokens.css."

    for token <- @land_tokens do
      assert block =~ ~r/#{Regex.escape(token)}\s*:/,
             "Expected `#{token}:` inside the [data-theme=\"light\"] block of " <>
               "assets/css/admin/tokens.css, per 01.8.2-TOKENS.md's LAND set."
    end
  end

  test "--val resolves to a different colour than --color-primary in each theme (D-33)" do
    tokens_src = strip_comments(tokens_source())
    app_css_src = strip_comments(app_css_source())
    ramp = ramp_map()

    for theme <- ["dark", "light"] do
      val_block = theme_block(tokens_src, theme)
      assert val_block, "No :root[data-theme=\"#{theme}\"] block in assets/css/admin/tokens.css."

      primary_block = daisyui_theme_block(app_css_src, theme)

      assert primary_block,
             "No @plugin daisyui-theme block for name: \"#{theme}\" in assets/css/app.css."

      val = val_block |> declared_value("--val") |> resolve(ramp)
      primary = primary_block |> declared_value("--color-primary") |> resolve(ramp)

      refute val == primary,
             "In the #{theme} theme, --val (#{val}) resolves to the SAME colour as " <>
               "--color-primary (#{primary}). D-33 exists precisely to give --val its own " <>
               ~s(ramp stop so "you can change this" and "you can't" are not the same colour.)
    end
  end

  test "--color-accent-bg and --color-accent-text never appear in the admin stylesheet (D-34 DISCARD)" do
    src = strip_comments(tokens_source())

    refute src =~ "--color-accent-bg",
           "assets/css/admin/tokens.css declares --color-accent-bg — 01.8.2-TOKENS.md marks " <>
             "this DISCARD (app.css:3991 already records it as never having existed upstream)."

    refute src =~ "--color-accent-text",
           "assets/css/admin/tokens.css declares --color-accent-text — 01.8.2-TOKENS.md marks " <>
             "this DISCARD; the \"Sin guardar\" dot resolves to --color-warning instead."
  end

  test "-webkit-tap-highlight-color is declared exactly once (D-19o)" do
    src = strip_comments(tokens_source())

    occurrences = src |> String.split("-webkit-tap-highlight-color") |> length() |> Kernel.-(1)

    assert occurrences == 1,
           "Expected exactly one `-webkit-tap-highlight-color` declaration in " <>
             "assets/css/admin/tokens.css (it inherits, so one :root declaration covers every " <>
             "pressable surface added later), found #{occurrences}."
  end
end
