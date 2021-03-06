defmodule Metrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Metrics.Application, []}
    ]
  end

  defp deps do
    []
  end
end
