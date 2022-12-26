defmodule AcceptanceTest do
  import TestHelpers
  use ExUnit.Case, async: true

  @tests [
    {"''", generate_token(:simple_string, "")},
    {"'hello'", generate_token(:simple_string, "hello")},
    {"\"\"", generate_token(:string, "")},
    {"\"hello\"", generate_token(:string, "hello")},
    {"0", generate_token(:integer, 0)},
    {"123", generate_token(:integer, 123)},
    {"0x123", generate_token(:integer, 291)},
    {"0b1011", generate_token(:integer, 11)},
    {"0.0", generate_token(:float, 0.0)},
    {"123.456", generate_token(:float, 123.456)}
  ]

  Enum.each(@tests, fn
    {source, token} ->
      tname = Map.get(token, :name)
      tvalue = Map.get(token, :value)

      test "String #{inspect(source)} results in token #{inspect(token)}" do
        result = ExampleLexer.lex(unquote(source))
        {ok, result} = result
        assert ok == :ok

        result = Enum.at(result, 0)

        rname = Map.get(result, :name)
        rvalue = Map.get(result, :value)
        assert rname == unquote(tname)
        assert rvalue == unquote(tvalue)
      end
  end)

  test "String #{inspect("'foo'\n'bar'")} has correct line numbers" do
    {ok, tokens} = ExampleLexer.lex("'foo'\n'bar'")
    assert ok == :ok

    token = List.last(tokens)
    assert token.line == 2
  end

  test "String #{inspect("'foo'\n'bar' 'baz'")} has correct column numbers" do
    {ok, tokens} = ExampleLexer.lex("'foo'\n'bar' 'baz'")
    assert ok == :ok

    token = List.last(tokens)
    assert token.value == "baz"
    assert token.column == 8
  end

  test "String #{inspect("abc")} emits a tokens _and_ handles state changes" do
    assert {:ok, tokens} = ExampleLexer.lex("abccba")
    assert [%{name: :abc, value: "abc"}, %{name: :cba, value: "cba"}] = tokens
  end
end
