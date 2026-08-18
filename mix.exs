defmodule PukllayClub.MixProject do
  use Mix.Project

  def project do
    [
      app: :pukllay_club,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      usage_rules: usage_rules(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}, plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PukllayClub.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        quality: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Config-driven usage_rules sync target (`mix rules.sync`): writes into the
  # EXISTING hand-written AGENTS.md, never CLAUDE.md (usage_rules' own default).
  # Only usage_rules' own rules (main + its elixir/otp builtin sub-rules) are
  # inlined; every other dependency's usage rules are linked (not inlined) via
  # the catch-all regex, which also picks up future deps automatically. The
  # regex excludes `usage_rules` itself so it isn't resolved (and duplicated)
  # a second time in link mode.
  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        {:usage_rules, sub_rules: ["elixir", "otp"]},
        {~r/^(?!usage_rules$).+/, link: :markdown}
      ]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.9"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.5", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.2.0", sparse: "optimized", app: false, compile: false, depth: 1},
      {:daisyui,
       github: "saadeghi/daisyui", tag: "v5.5.20", sparse: "packages/bundle", app: false, compile: false, depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.12", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:tidewave, "~> 0.8", only: :dev},
      {:usage_rules, "~> 1.1", only: [:dev]},
      {:igniter, "~> 0.6", only: [:dev]},
      {:sentry, "~> 13.0"},
      {:sweet_xml, "~> 0.7.5"},
      {:image, "~> 0.72.0"},
      {:ex_aws, "~> 2.7"},
      {:ex_aws_s3, "~> 2.5"},
      {:nimble_csv, "~> 1.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind pukllay_club", "esbuild pukllay_club"],
      "assets.deploy": [
        "tailwind pukllay_club --minify",
        "esbuild pukllay_club --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"],
      "rules.sync": ["usage_rules.sync"],
      quality: [
        "hex.audit",
        "deps.audit",
        "deps.unlock --check-unused",
        "format --check-formatted",
        "credo --strict",
        "sobelow --config",
        "test --warnings-as-errors"
      ]
    ]
  end
end
