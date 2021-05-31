defmodule Jaxon.MixProject do
  use Mix.Project

  def project do
    [
      app: :jaxon,
      name: "Jaxon",
      version: "2.0.1",
      elixir: "~> 1.7",
      compilers: [:elixir_make] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "bench.encode": :bench,
        "bench.decode": :bench,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/boudra/jaxon",
      description: description(),
      package: package()
    ]
  end

  defp description() do
    "Jaxon is an efficient and simple event-based JSON parser for Elixir, it's main goal is to be able to parse huge JSON files with minimal memory footprint."
  end

  defp package() do
    [
      name: "jaxon",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "Makefile", "c_src/*.[ch]"],
      maintainers: ["Mohamed Boudra"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/boudra/jaxon"}
    ]
  end

  defp aliases() do
    [
      "bench.encode": ["run bench/encode.exs"],
      "bench.decode": ["run bench/decode.exs"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.0", only: :bench},
      {:benchee_html, "~> 1.0", only: :bench},
      {:poison, ">= 0.0.0", only: [:bench]},
      {:jason, ">= 0.0.0", only: [:bench, :test, :docs]},
      {:jiffy, ">= 0.0.0", only: :bench},
      {:ex_doc, ">= 0.0.0", only: [:docs, :dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:test, :dev], runtime: false},
      {:inch_ex, github: "rrrene/inch_ex", only: [:docs, :test]},
      {:elixir_make, "~> 0.4", runtime: false},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end
end
