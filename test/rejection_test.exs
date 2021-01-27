defmodule RejectionTest do
  use ExUnit.Case, async: true

  test "string not in language fails" do
    {status, message} = ExampleLexer.lex("{}")
    assert status == :error
    assert message == "String not in language: \"{}\""
  end

  test "bogus action" do
    {status, message} = ExampleLexer.lex("BOGUS_ACTION")
    assert status == :error
    assert message == "Invalid result from action: \"WAT\""
  end
end
