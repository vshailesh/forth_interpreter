defmodule ParserTest do
  use ExUnit.Case

  test "simple expression parsing" do
    alias ForthInterpreter.Driver
    parsed = Driver.new("1 2 +")
    assert parsed === [[simple_expression: [number: 1, number: 2, op: :addition]] | nil]
  end

  test "larger arithmetic expression parsing" do
    alias ForthInterpreter.Driver
    parsed = Driver.new("1 2 + 3 *")

    assert parsed === [
             [
               simple_expression: [
                 number: 1,
                 number: 2,
                 op: :addition,
                 number: 3,
                 op: :multiplication
               ]
             ]
             | nil
           ]
  end

  test "complex arithmetic expression parsing" do
    alias ForthInterpreter.Driver
    parsed = Driver.new("1 2 + 3 * 4 -")

    assert parsed === [
             [
               simple_expression: [
                 number: 1,
                 number: 2,
                 op: :addition,
                 number: 3,
                 op: :multiplication,
                 number: 4,
                 op: :subtraction
               ]
             ]
             | nil
           ]
  end
end
