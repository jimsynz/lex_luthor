defmodule LexLuthor.Mixfile do
  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :lex_luthor,
      version: @version,
      elixir: "~> 1.11",
      description:
        "LexLuthor is a Lexer in Elixir (say that 10 times fast) which uses macros to generate a reusable lexers. Good times.",
      source_url: "https://harton.dev/james/lex_luthor",
      package: [
        maintainers: ["James Harton <james@harton.nz>"],
        licenses: ["MIT"],
        links: %{"Source" => "https://harton.dev/james/lex_luthor"}
      ],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [extra_applications: [:logger]]
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
      {:credo, "~> 1.5", only: ~w[dev test]a},
      {:ex_check, "~> 0.16.0", only: ~w[dev test]a},
      {:ex_doc, ">= 0.0.0", only: ~w[dev test]a},
      {:git_ops, "~> 2.4", only: ~w[dev test]a, runtime: false},
      {:mix_audit, "~> 2.1", only: ~w[dev test]a}
    ]
  end
end
