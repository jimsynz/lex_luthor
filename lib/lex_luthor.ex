defmodule LexLuthor do

  @rules []
  @action_no 0

  defmodule State do
    defstruct pos: 0, states: [nil], tokens: []
  end

  defmodule Token do
    defstruct pos: 0, name: nil, value: nil
  end

  defmacro __using__(_opts) do
    quote do
      @rules []
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
    function_name = "_action_#{inspect(regex)}_#{Atom.to_string state}" |> String.to_atom
    quote do
      def unquote(function_name)(e) do
        unquote(block).(e)
      end

      @rules(@rules ++ [{ unquote(state), unquote(regex), unquote(function_name) }])
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
        # Increment lexer position
        lexer = %State{ pos: lexer.pos + len, states: lexer.states, tokens: lexer.tokens }

        # Are we at the end of the string?
        if String.length(string) == len do
          { :ok, Enum.reverse lexer.tokens }
        else
          { _ , new_string } = String.split_at string, len
          do_lex module, rules, new_string, lexer
        end
    end
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
    token = %Token{ pos: lexer.pos, name: tname, value: tvalue }
    %State{ pos: lexer.pos, states: lexer.states, tokens: [ token | lexer.tokens ] }
  end

  defp push_state lexer, state do
    %State{ pos: lexer.pos, states: [ state | lexer.states ], tokens: lexer.tokens }
  end

  defp pop_state lexer do
    [ _ | states ] = lexer.states
    %State{ pos: lexer.pos, states: states, tokens: lexer.tokens }
  end

  defp rules_for_state rules, state do
    Enum.filter rules, fn({rule_state,_,_})->
      if is_nil(state) do
        state = :default
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
