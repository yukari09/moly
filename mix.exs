defmodule Moly.MixProject do
  use Mix.Project

  def project do
    [
      app: :moly,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Moly.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:snap, "~> 0.12"},
      {:timex, "~> 3.7.11"},
      {:flame, "~> 0.5"},
      {:ash_rbac, "~> 0.6.1"},
      {:lucide_icons, "~> 2.0.0"},
      {:ash_authentication_phoenix, "~> 2.10"},
      {:ash_authentication, "~> 4.9"},
      {:bcrypt_elixir, "~> 3.2"},
      {:picosat_elixir, "~> 0.2"},
      {:ash_postgres, "~> 2.5.6"},
      {:ash_phoenix, "~> 2.2"},
      {:ash, "~> 3.5"},
      {:cachex, "~> 4.0"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.20"},
      {:sweet_xml, "~> 0.7"},
      {:gen_smtp, "~> 1.3"},
      {:oban, "~> 2.19"},
      {:slugify, "~> 1.3"},
      {:sitemapper, "~> 0.9"},
      {:tidewave, "~> 0.1", only: :dev},
      {:ash_graphql, "~> 1.7.15"},
      {:mdex, "~> 0.7"},
      # ====================
      {:phoenix, "~> 1.7.20"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.37.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:igniter, "~> 0.5", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.18.4"},
      {:finch, "~> 0.19"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:dns_cluster, "~> 0.2"},
      {:bandit, "~> 1.6.11"}
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
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind moly", "tailwind admin", "esbuild moly"],
      "assets.deploy": [
        "tailwind moly --minify",
        "tailwind admin --minify",
        "esbuild moly --minify",
        "phx.digest"
      ]
    ]
  end
end
