defmodule LexLuthor do
  alias LexLuthor.Runner

  @moduledoc """
  LexLuthor is a Lexer in Elixir (say that 10 times fast) which uses macros to generate a reusable lexers. Good times.

  LexLuthor is a state based lexer, meaning that it keeps a state stack which you can push states on and pop states off the stack, which are used to filter the applicable rules for a given state.  For example:

      iex> defmodule StringLexer do
      ...>   use LexLuthor
      ...>   defrule ~r/^'/,              fn(_) -> :STRING end
      ...>   defrule ~r/^[^']+/, :STRING, fn(e) -> { :string, e } end
      ...>   defrule ~r/^'/,     :STRING, fn(_) -> nil end
      ...> end
      ...> StringLexer.lex("'foo'")
      {:ok, [%LexLuthor.Token{column: 1, line: 1, name: :string, pos: 1, value: "foo"}]}

  Rules are defined by a regular expression, an optional state (as an atom) and an action in the form of an anonymous function.

  When passed the string `'foo'`, the lexer starts in the `:default` state, so it filters for rules in the default state (the first rule, as it doesn't specify a state), then it filters the available rules by the longest matching regular expression.  In this case, since we have only one rule (which happens to match) it's automatically the longest match.

  Once the longest match is found, then it's action is executed and the return value matched:
    - If the return value is a single atom then that atom is assumed to be a state and push onto the top of the state stack.
    - If the return value is a two element tuple then the first element is expected to be an atom (the token name) and the second element a value for this token.
    - If the return value is `nil` then the top state is popped off the state stack.

  If lexing succeeds then you will receive an `:ok` tuple with the second value being a list of `LexLuthor.Token` structs.

  If lexing fails then you will receive an `:error` tuple which a reason and position.
  """

  defmacro __using__(_opts) do
    quote do
      @rules []
      @action_counter 0
      import LexLuthor
      @before_compile LexLuthor
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def lex(string) do
        Runner.lex(__MODULE__, @rules, string)
      end
    end
  end

  @doc """
  Define a lexing rule for a specific state.

  - `regex` a regular expression for matching against the input string.
  - `state` the lexer state in which this rule applies.
  - `action` the function to execute when this rule is applied.
  """
  @spec defrule(Regex.t(), atom, (String.t() -> atom | nil | {atom, any})) ::
          {:ok, non_neg_integer}
  defmacro defrule(regex, state, action) do
    quote do
      @action_counter @action_counter + 1
      action_name = "_action_#{@action_counter}" |> String.to_atom()
      action = unquote(Macro.escape(action))

      defaction =
        quote do
          def unquote(Macro.escape(action_name))(e) do
            unquote(action).(e)
          end
        end

      Module.eval_quoted(__MODULE__, defaction)

      @rules @rules ++ [{unquote(state), unquote(regex), action_name}]
      {:ok, Enum.count(@rules)}
    end
  end

  @doc """
  Define a lexing rule applicable to the default state.

  - `regex` a regular expression for matching against the input string.
  - `action` the function to execute when this rule is applied.
  """
  defmacro defrule(regex, action) do
    quote do
      defrule(unquote(regex), :default, unquote(action))
    end
  end
end
