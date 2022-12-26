defmodule TestHelpers do
  def generate_token(name, value) do
    %LexLuthor.Token{name: name, value: value}
  end
end

defmodule ExampleLexer do
  use LexLuthor

  # single tick strings
  defrule(~r/^''/, fn _ -> {:simple_string, ""} end)
  defrule(~r/^'/, fn _ -> :simple_string end)
  defrule(~r/^[^']+/, :simple_string, fn e -> {:simple_string, e} end)
  defrule(~r/^'/, :simple_string, fn _ -> nil end)

  # double tick strings
  defrule(~r/^""/, fn _ -> {:string, ""} end)
  defrule(~r/^"/, fn _ -> :string end)
  defrule(~R/^#{/, :string, fn _ -> :default end)
  defrule(~R/^}/, :default, fn _ -> nil end)
  defrule(~R/^[^("|#{)]+/, :string, fn e -> {:string, e} end)
  defrule(~r/^"/, :string, fn _ -> nil end)

  # floats
  defrule(~r/^[0-9]+\.[0-9]+/, fn e -> {:float, String.to_float(e)} end)

  # integers
  defrule(~r/^0x[0-9a-fA-F]+/, fn e ->
    [_ | i] = String.split(e, "x")
    {:integer, String.to_integer(Enum.at(i, 0), 16)}
  end)

  defrule(~r/^0b[01]+/, fn e ->
    [_ | i] = String.split(e, "b")
    {:integer, String.to_integer(Enum.at(i, 0), 2)}
  end)

  defrule(~r/^[1-9][0-9]*/, fn e -> {:integer, String.to_integer(e)} end)
  defrule(~r/^0/, fn _ -> {:integer, 0} end)

  # white space
  defrule(~r/^[ \t]+/, fn e -> {:ws, String.length(e)} end)
  defrule(~r/^\r\n/, fn _ -> {:nl, 1} end)
  defrule(~r/^\r/, fn _ -> {:nl, 1} end)
  defrule(~r/^\n/, fn _ -> {:nl, 1} end)

  # bogus action
  defrule(~r/^BOGUS_ACTION/, fn _ -> "WAT" end)

  # double results
  defrule(~r/abc/, fn _ -> [:abc, {:abc, "abc"}] end)
  defrule(~r/cba/, :abc, fn _ -> [{:cba, "cba"}, nil] end)
end

ExUnit.start()
