defmodule LexLuthor.Runner do
  alias LexLuthor.{State, Token}

  @moduledoc """
  This module runs a Lexer module against an input string.

  You don't use it directly as `YourModule.lex/1` is defined on
  your module when you `use LexLuthor`.
  """

  @doc """
  Process a string against a given Lexer module and rules.

    - `module` the module in which the lexer is defined.
    - `rules` an array of rules to apply to the input string.
    - `string` the input string to be lexed.
  """
  @spec lex(atom, [{atom, Regex.t, String.t}], String.t) :: {:ok, non_neg_integer}
  def lex module, rules, string do
    do_lex module, rules, string, %State{}
  end

  defp do_lex module, rules, string, lexer do
    [current_state | _rest] = lexer.states

    # Find the longest matching rule. This could
    # probably be made a whole lot less enumeratey.
    matches = rules
      |> rules_for_state(current_state)
      |> matching_rules(string)
      |> apply_matches(string)
      |> longest_match_first

    process_matches module, rules, matches, string, lexer, Enum.count(matches)
  end

  defp process_matches(_, _, _, string, _, count) when count == 0 do
    {:error, "String not in language: #{inspect string}"}
  end

  defp process_matches(module, rules, matches, string, lexer, count) when count > 0 do
    match = Enum.at matches, 0

    # Execute the matches' action.
    {len, value, fun} = match
    result = apply(module, fun, [value])

    lexer = process_result result, lexer

    case lexer do
      { :error, _ } ->
        lexer
      _ ->

        fragment = String.slice string, 0, len
        line     = lexer.line + line_number_incrementor fragment
        column   = column_number lexer, fragment

        lexer = Map.merge(lexer, %{pos:    lexer.pos + len,
                                   line:   line,
                                   column: column})

        # Are we at the end of the string?
        if String.length(string) == len do
          { :ok, Enum.reverse lexer.tokens }
        else
          { _ , new_string } = String.split_at string, len
          do_lex module, rules, new_string, lexer
        end
    end
  end

  defp column_number lexer, match do
    case Regex.match? ~r/[\r\n]/, match do
      true ->
        len = match |> split_on_newlines |> List.last |> String.length
        case len do
          0 -> 1
          _ -> len
        end
      false ->
        lexer.column + String.length match
    end
  end

  defp line_number_incrementor match do
    (match |> split_on_newlines |> Enum.count) - 1
  end

  defp split_on_newlines string do
    string |> String.split(~r{(\r|\n|\r\n)})
  end

  defp process_result(result, lexer) when is_nil(result) do
    pop_state lexer
  end

  defp process_result(result, lexer) when is_atom(result) do
    push_state lexer, result
  end

  defp process_result(result, lexer) when is_tuple(result) do
    push_token lexer, result
  end

  defp process_result result, _ do
    {:error, "Invalid result from action: #{inspect result}"}
  end

  defp push_token lexer, token do
    {tname, tvalue} = token
    token = %Token{pos:    lexer.pos,
                   line:   lexer.line,
                   column: lexer.column,
                   name:   tname,
                   value:  tvalue}
    Map.merge lexer, %{tokens: [token | lexer.tokens ]}
  end

  defp push_state lexer, state do
    Map.merge lexer, %{states: [state | lexer.states ]}
  end

  defp pop_state lexer do
    [ _ | states ] = lexer.states
    Map.merge lexer, %{states: states}
  end

  defp rules_for_state rules, state do
    Enum.filter rules, fn({rule_state,_,_}) ->
      state = if is_nil(state) do
        :default
      else
        state
      end
      state == rule_state
    end
  end

  defp matching_rules rules, string do
    Enum.filter rules, fn({_,regex,_}) ->
      Regex.match?(regex, string)
    end
  end

  defp apply_matches rules, string do
    Enum.map rules, fn({_,regex,fun}) ->
      [match] = Regex.run(regex,string, capture: :first)
      { String.length(match), match, fun }
    end
  end

  defp longest_match_first matches do
    Enum.sort_by matches, fn({len,_,_}) -> len end, &>=/2
  end
end
