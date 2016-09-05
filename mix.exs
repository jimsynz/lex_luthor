defmodule LexLuthor.Mixfile do
  use Mix.Project

  def project do
    [app: :lex_luthor,
     version: "0.1.1",
     elixir: "~> 1.0",
     description: "LexLuthor is a Lexer in Elixir (say that 10 times fast) which uses macros to generate a reusable lexers. Good times.",
     source_url: "https://github.com/jamesotron/lex_luthor",
     package: [
       contributors: ["James Harton"],
       licenses: ["MIT"],
       links: %{"Source" => "https://github.com/jamesotron/lex_luthor"}
     ],
     deps: deps]
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
    []
  end
end
