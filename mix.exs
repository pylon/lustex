defmodule Lustex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lustex,
      name: "Lustex",
      version: "0.2.0",
      elixir: "~> 1.6",
      description: "Lua-based string templates for Elixir",
      deps: deps(),
      package: package(),
      dialyzer: [
        ignore_warnings: ".dialyzerignore",
        plt_add_deps: :transitive
      ],
      docs: [extras: ["README.md"]]
    ]
  end

  defp deps do
    [
      {:luerl, "~> 0.3.0"},
      {:credo, "~> 0.5", only: :dev, runtime: false},
      {:dogma, "~> 0.1", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["mix.exs", "README.md", "lib", "src"],
      maintainers: ["Brent M. Spell"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/pylon/lustex",
        "Docs" => "http://hexdocs.pm/lustex/"
      }
    ]
  end
end
