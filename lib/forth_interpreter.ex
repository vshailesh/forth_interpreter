defmodule ForthInterpreter.Helpers do
  import NimbleParsec
  # import ForthInterpreter.HelperForHelpers

  whitespace = times(string(" "), min: 0)
  arithmetic_operator =
    choice([
      string("+") |> unwrap_and_tag(:add),
      string("-") |> unwrap_and_tag(:subtraction),
      string("*") |> unwrap_and_tag(:multiplication),
      string("/") |> unwrap_and_tag(:division),
      string("mod") |> unwrap_and_tag(:mod),
      string(".") |> unwrap_and_tag(:print),
      string("dup") |> unwrap_and_tag(:dup),
      string("drop") |> unwrap_and_tag(:drop),
      string("swap") |> unwrap_and_tag(:swap),
      string("over") |> unwrap_and_tag(:over)
    ])

  defp parse_number(parts) do
    number_string =
      Enum.map_join(parts, fn
        ?- -> "-"
        ?+ -> "+"
        part when is_binary(part) -> part
      end)

      case Integer.parse(number_string) do
        {value, ""} ->
          value
        {_value, _remainder} ->
          {value, ""} = Float.parse(number_string)
          value
      end
  end

  parse_number =
    [?-, ?+]
    |> ascii_char()
    |> optional()
    |> ascii_string([?0..?9], min: 1)
    |> optional(
      "."
      |> string()
      |> ascii_string([?0..?9], min: 1)
    )
    |> reduce(:parse_number)
    |> unwrap_and_tag(:number)

  defcombinatorp :extended_expression,
                  optional(ignore(whitespace))
                  |> concat(parse_number)
                  |> ignore(whitespace)
                  |> concat(arithmetic_operator)
                  |> optional(parsec(:extended_expression))

  # operand =
  #   choice([
  #     parse_number,
  #     wrap(parsec(:simple_expression))
  #   ])

  defcombinator(
    :simple_expression,
    ignore(whitespace)
    |> concat(parse_number)
    |> ignore(whitespace)
    |> concat(parse_number)
    |> ignore(whitespace)
    |> concat(arithmetic_operator)
    |> optional(ignore(whitespace))
    |> optional(parsec(:extended_expression))
  )

  # defcombinator(
  #   :just_stack_push
  # )

end

defmodule ForthInterpreter.EntryPoint do
  @moduledoc """
  Documentation for `ForthInterpreter`.
  """
  import NimbleParsec
  import ForthInterpreter.Helpers
  defparsec(:expr, parsec(:simple_expression))
  # defparsec(:keywords_expr, parsec(:keyword_expression))
end

defmodule ForthInterpreter.Driver do
  import ForthInterpreter.EntryPoint

  def new("") do
    :ok
  end
  def new(input) do
    # {:ok, parsed, input, _, _, _} = ForthInterpreter.EntryPoint.simple_expr(input)
    # parsed
    ForthInterpreter.EntryPoint.expr(input)
  end
  def new_from_file() do
  end
end
