defmodule Lustex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lustex,
      name: "Lustex",
      version: "0.2.0",
      elixir: "~> 1.7",
      description: "Lua-based string templates for Elixir",
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.post": :test
      ],
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
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 0.10", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
