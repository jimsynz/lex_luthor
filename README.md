# LexLuthor

LexLuthor is a Lexer in Elixir (say that 10 times fast) which uses macros to generate a reusable lexers. Good times.

LexLuthor is a state based lexer, meaning that it keeps a state stack which you can push states on and pop states off the stack, which are used to filter the applicable rules for a given state.  For example:

```elixir
defmodule StringLexer do
  use LexLuthor

  defrule ~r/^'/,              fn(_) -> :STRING end
  defrule ~r/^[^']+/, :STRING, fn(e) -> { :string, e } end
  defrule ~r/^'/,     :STRING, fn(_) -> nil end
end
```

Rules are defined by a regular expression, an optional state (as an atom) and an action in the form of an anonymous function.

When passed the string `'foo'`, the lexer starts in the `:default` state, so it filters for rules in the default state (the first rule, as it doesn't specify a state), then it filters the available rules by the longest matching regular expression.  In this case, since we have only one rule (which happens to match) it's automatically the longest match.

Once the longest match is found, then it's action is executed and the return value matched:
  - If the return value is a single atom then that atom is assumed to be a state and push onto the top of the state stack.
  - If the return value is a two element tuple then the first element is expected to be an atom (the token name) and the second element a value for this token.
  - If the return value is `nil` then the top state is popped off the state stack.

If lexing succeeds then you will receive an `:ok` tuple with the second value being a list of `LexLuthor.Token` structs.

If lexing fails then you will receive an `:error` tuple which a reason and position.

## Contributing

1. Fork it ( https://github.com/jamesotron/lex_luthor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
