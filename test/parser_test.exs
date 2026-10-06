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

  test "parsing N_op stack operation expression" do
    alias ForthInterpreter.Driver
    parsed = Driver.new("1 2 + 2dup")
    assert parsed === [
      [simple_expression: [number: 1, number: 2, op: :addition]],
      [simple_expr2: [n_op_expr: [number: 2, op: :dup]]] |
      nil
    ]
  end

  test "unterminated word definition" do
    alias ForthInterpreter.Driver
    parsed = Driver.new(": double dup +")
    assert parsed === {:error, "unterminated definition"}
  end

  test "invalid start of word definition" do
    alias ForthInterpreter.Driver
    parsed = Driver.new(":double dup + ;")
    assert parsed === {:error, "invalid word definition"}
  end
end
