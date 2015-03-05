defmodule LexLuthorTest do
  import TestHelpers
  use ExUnit.Case, async: true

  @tests [
    { "''",        generate_token(:simple_string, "") },
    { "'hello'",   generate_token(:simple_string, "hello") },
    { "\"\"",      generate_token(:string, "") },
    { "\"hello\"", generate_token(:string, "hello") },
    { "0",         generate_token(:integer, 0) },
    { "123",       generate_token(:integer, 123) },
    { "0x123",     generate_token(:integer, 291) },
    { "0b1011",    generate_token(:integer, 11) },
    { "0.0",       generate_token(:float, 0.0) },
    { "123.456",   generate_token(:float, 123.456) }
  ]

  Enum.each @tests, fn
    { source,  token } ->
      tname  = Map.get token, :name
      tvalue = Map.get token, :value

      test "String #{inspect(source)} results in token #{inspect(token)}" do
        result = Enum.at(ExampleLexer.lex(unquote(source)), 0)

        rname  = Map.get result, :name
        rvalue = Map.get result, :value
        assert rname  == unquote(tname)
        assert rvalue == unquote(tvalue)
      end
  end

end
