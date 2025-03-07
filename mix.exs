defmodule BraveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :brave_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:req, "~> 0.5.8"},
      {:ex_doc, "~> 0.37.2", only: :dev, runtime: false}

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
