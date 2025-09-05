defmodule ExStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_storage,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExStorage.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.2.3"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7.12", only: [:dev, :test], runtime: false}
    ]
  end
end
