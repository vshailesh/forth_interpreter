defmodule ParserTest do
  use ExUnit.Case

  test "simple expression parsing" do
    alias ForthInterpreter.EntryPoint
    {:ok, parsed, rest, _, _, _} = EntryPoint.expr("1 2 +")
    assert parsed === [number: 1, number: 2, add: "+"]
  end

  test "larger arithmetic expression parsing" do
    alias ForthInterpreter.EntryPoint
    {:ok, parsed, rest, _, _, _} = EntryPoint.expr("1 2 + 3 *")
    assert parsed === [number: 1, number: 2, add: "+", number: 3, multiplication: "*"]
  end

  test "complex arithmetic expression parsing" do
    alias ForthInterpreter.EntryPoint
    {:ok, parsed, rest, _, _, _} = EntryPoint.expr("1 2 + 3 * 4 -")
    assert parsed === [
      number: 1,
      number: 2,
      add: "+",
      number: 3,
      multiplication: "*",
      number: 4,
      subtraction: "-"
    ]
  end
end
