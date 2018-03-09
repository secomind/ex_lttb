defmodule ExLTTB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_lttb,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:stream_data, "~> 0.1", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Riccardo Binetti", "Davide Bettio"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ispirata/ex_lttb"}
    ]
  end
end
