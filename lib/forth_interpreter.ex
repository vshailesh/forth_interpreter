defmodule ForthInterpreter.Helpers do
  import NimbleParsec

  def arithmetic() do
    val = integer(min: 1)
  end

  def skip_whitespaces() do
  end

  operator =
    choice([
      string("+"),
      string("-"),
      string("*"),
      string("/"),
      string("mod"),
      string(".")
    ])

  whitespace = times(string(" "), min: 0)

  operand =
    choice([
      integer(min: 1),
      wrap(parsec(:expression))
    ])

  defcombinator(
    :expression,
    ignore(whitespace)
    |> optional(operator)
    |> concat(operand)
    |> ignore(whitespace)
    |> concat(operand)
    |> ignore(whitespace)
    |> concat(operator)
    |> optional(ignore(whitespace))
    |> optional(operator)
  )

  # defcombinator(
  #   :expression2,
  #   ignore(whitespace),
  #   |> concat
  # )
end

defmodule ForthInterpreter.EntryPoint do
  @moduledoc """
  Documentation for `ForthInterpreter`.
  """
  import NimbleParsec
  import ForthInterpreter.Helpers
  defparsec(:forth, parsec(:expression))
end

defmodule ForthInterpreter.Driver do
  import ForthInterpreter.EntryPoint

  def new(input) do
    # {:ok, parsed, rest, _, _, _} = ForthInterpreter.EntryPoint.forth(input)
    ForthInterpreter.EntryPoint.forth(input)
    # parsed
  end

  def new_from_file() do
  end
end
