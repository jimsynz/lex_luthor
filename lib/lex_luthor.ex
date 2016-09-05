defmodule LexLuthor do
  defmodule State do
    defstruct pos: 0, line: 1, column: 0, states: [nil], tokens: []
  end

  defmodule Token do
    defstruct pos: 0, line: 1, column: 0, name: nil, value: nil
  end

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
      def lex string do
        LexLuthor.lex __MODULE__, @rules, string
      end
    end
  end

  defmacro defrule(regex, state, block) do
    quote do
      @action_counter(@action_counter + 1)
      action_name = "_action_#{@action_counter}" |> String.to_atom
      block       = unquote(Macro.escape(block))

      defaction = quote do
        def unquote(Macro.escape(action_name))(e) do
          unquote(block).(e)
        end
      end
      Module.eval_quoted __MODULE__, defaction

      @rules(@rules ++ [{ unquote(state), unquote(regex), action_name }])
      { :ok, Enum.count(@rules) }
    end
  end

  defmacro defrule(regex, block) do
    quote do
      defrule unquote(regex), :default, unquote(block)
    end
  end

  def lex module, rules, string do
    do_lex module, rules, string, %State{}
  end

  defp do_lex module, rules, string, lexer do
    [ current_state | _rest ] = lexer.states

    # Find the longest matching rule. This could
    # probably be made a whole lot less enumeratey.
    matches = rules_for_state(rules, current_state)
      |> matching_rules(string)
      |> apply_matches(string)
      |> longest_match_first

    process_matches module, rules, matches, string, lexer, Enum.count(matches)
  end

  defp process_matches(_, _, _, string, _, count) when count == 0 do
    { :error, "String not in language: #{inspect string}"}
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

        lexer = Map.merge lexer, %{pos: lexer.pos + len, line: line, column: column}

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

  def split_on_newlines string do
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
    { :error, "Invalid result from action: #{inspect result}"}
  end

  defp push_token lexer, token do
    { tname, tvalue } = token
    token = %Token{ pos: lexer.pos, line: lexer.line, column: lexer.column, name: tname, value: tvalue }
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
    Enum.filter rules, fn({rule_state,_,_})->
      state = if is_nil(state) do
        :default
      else
        state
      end
      state == rule_state
    end
  end

  defp matching_rules rules, string do
    Enum.filter rules, fn({_,regex,_})->
      Regex.match?(regex, string)
    end
  end

  defp apply_matches rules, string do
    Enum.map rules, fn({_,regex,fun})->
      [match] = Regex.run(regex,string, capture: :first)
      { String.length(match), match, fun }
    end
  end

  defp longest_match_first matches do
    Enum.sort_by matches, fn({len,_,_})-> len end, &>=/2
  end

end
