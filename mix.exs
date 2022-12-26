defmodule LexLuthor.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lex_luthor,
      version: "0.1.3",
      elixir: "~> 1.0",
      description:
        "LexLuthor is a Lexer in Elixir (say that 10 times fast) which uses macros to generate a reusable lexers. Good times.",
      source_url: "https://github.com/jimsynz/lex_luthor",
      preferred_cli_env: [inch: :docs],
      package: [
        contributors: ["James Harton"],
        licenses: ["MIT"],
        links: %{"Source" => "https://github.com/jimsynz/lex_luthor"}
      ],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 1.5", only: ~w(dev test)a}
    ]
  end
end
