defmodule Jaxon.MixProject do
  use Mix.Project

  def project do
    [
      app: :jaxon,
      name: "Jaxon",
      version: "1.0.6",
      elixir: "~> 1.6",
      compilers: [:elixir_make] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "bench.encode": :bench,
        "bench.decode": :bench,
        docs: :docs,
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
      {:benchee, "~> 0.8", only: :bench},
      {:benchee_html, "~> 0.1", only: :bench},
      {:poison, "~> 3.0", only: [:bench, :docs]},
      {:jason, "~> 1.0", only: :bench},
      {:jiffy, "~> 0.14", only: :bench},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, "~> 0.5", only: :docs},
      {:elixir_make, "~> 0.4", runtime: false},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end
end
