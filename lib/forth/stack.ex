defmodule Forth.Stack do
  def new(init_stack) do
    case init_stack do
      [] -> []
      _ -> init_stack
    end
  end

  def push(element, stack) do
    [element | stack]
  end

  def pop([]) do
    {:error, "stack underflow"}
  end

  def pop([head | tail]) do
    {head, tail}
  end

  def peek([]), do: []

  def peek([head | tail]) do
    {head, [head | tail]}
  end

  def reverse(stack) do
    Enum.reverse(stack)
  end
end
