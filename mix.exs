defmodule Funbunn.MixProject do
  use Mix.Project

  def project do
    [
      app: :funbunn,
      version: "0.2.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Funbunn.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.3.1"},
      {:sweet_xml, "~> 0.7.1"},
      {:jason, "~> 1.4"},
      {:phoenix_pubsub, "~> 2.0"},
      {:con_cache, "~> 1.0"}
    ]
  end

  defp aliases do
    [
    ]
  end
end
