defmodule LexLuthor.Token do
  defstruct pos: 0, line: 1, column: 0, name: nil, value: nil

  @moduledoc """
  Defines an individual token in the lexer output, along with handy stuff like
  the line and column numbers.
  """
end
