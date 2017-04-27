defmodule LexLuthor.State do
  defstruct pos: 0, line: 1, column: 0, states: [nil], tokens: []

  @moduledoc false
end
