defmodule BraveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :brave_ex,
      version: "0.1.2",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Programatically search Brave using Elixir",
      package: package(),
      deps: deps(),
      docs: [
        main: "BraveEx",
        extras: ["README.md"]
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
      # Floors skip releases with published advisories and still allow the
      # patched lines: req 0.6.1+ and 0.7.x, mint 1.10.2+ and 1.11.x, hpax 1.0.4+.
      {:req, "~> 0.6.1 or ~> 0.7.0"},
      {:mint, "~> 1.10.2 or ~> 1.11.0"},
      {:hpax, "~> 1.0.4 or ~> 1.1"},
      {:ex_doc, "~> 0.37.2 or ~> 0.38.0 or ~> 0.39.0 or ~> 0.40.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["BSD-3-Clause"],
      links: %{
        "GitHub" => "https://github.com/osintowl/BraveEx"
      }
    ]
  end
end
