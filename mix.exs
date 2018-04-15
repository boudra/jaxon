defmodule Mix.Tasks.Compile.Nifs do
  def run(_args) do
    case System.cmd("make", ["decoder.so"]) do
      {_, 0} ->
        :ok

      {result, _} ->
        IO.binwrite(result)
    end
  end
end

defmodule Jaxon.MixProject do
  use Mix.Project

  def project do
    [
      app: :jaxon,
      name: "Jaxon",
      version: "0.1.0",
      elixir: "~> 1.6",
      compilers: [:nifs] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Mohamed Boudra"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/boudra/jaxon"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
