defmodule ForthInterpreter.Helpers do
  import NimbleParsec

  whitespace = times(string(" "), min: 0)

  arithmetic_operator =
    choice([
      string("+") |> replace(:add),
      string("-") |> replace(:subtraction),
      string("*") |> replace(:multiplication),
      string("/") |> replace(:division),
      string("plus") |> replace(:add),
      string("mod") |> replace(:mod)
    ])
    |> unwrap_and_tag(:op)

  print_stack = string(" . ") |> replace(:print) |> unwrap_and_tag(:op)

  stack_operation =
    choice([
      string("dup") |> replace(:dup),
      string("drop") |> replace(:drop),
      string("swap") |> replace(:swap),
      string("over") |> replace(:over),
      string("rot") |> replace(:rot),
      string("nip") |> replace(:nip),
      string("tuck") |> replace(:tuck)
    ])
    |> unwrap_and_tag(:op)

  binary_logical_operator =
    choice([
      string("and") |> replace(:and),
      string("or") |> replace(:or)
    ])
    |> unwrap_and_tag(:op)

  unary_logical_operator =
    choice([
      string("not") |> replace(:not),
      string("invert") |> replace(:invert)
    ])
    |> unwrap_and_tag(:op)

  comparison_operator =
    choice([
      string("=") |> replace(:eq),
      string(">") |> replace(:gt),
      string("<") |> replace(:lt)
    ])
    |> unwrap_and_tag(:op)

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

  defp make_word(parts) do
    # IO.puts("MAKE WORDS => #{parts}")
    to_string(parts)
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

  parse_word =
    ascii_string([?a..?z], min: 1)
    |> reduce(:make_word)

  defcombinatorp(
    :extended_expression,
    optional(ignore(whitespace))
    |> concat(parse_number)
    |> ignore(whitespace)
    |> concat(arithmetic_operator)
    |> optional(parsec(:extended_expression))
  )

  defcombinatorp(
    :maybe_number,
    ignore(whitespace)
    |> concat(parse_number)
    |> optional(parsec(:maybe_number))
  )

  defcombinatorp(
    :parse_stack_keywords,
    ignore(whitespace)
    |> concat(stack_operation)
    |> optional(parsec(:parse_stack_keywords))
  )

  defcombinatorp(
    :comparison_op_kw,
    ignore(whitespace)
    |> concat(comparison_operator)
    |> optional(parsec(:comparison_op_kw))
  )

  defcombinatorp(
    :binary_logical_op_parse,
    ignore(whitespace)
    |> concat(binary_logical_operator)
    |> optional(parsec(:binary_logical_op_parse))
  )

  defcombinatorp(
    :unary_logical_op_parse,
    ignore(whitespace)
    |> concat(unary_logical_operator)
    |> optional(parsec(:unary_logical_op_parse))
  )

  defcombinatorp(
    :a_word2,
    optional(ignore(whitespace))
    |> concat(parse_word)
    |> unwrap_and_tag(:fn_name)
    |> optional(parsec(:a_word2))
  )

  defcombinatorp(
    :stack_op_kw_only,
    ignore(whitespace)
    |> concat(stack_operation)
    |> optional(parsec(:stack_op_kw_only))
  )

  defcombinatorp(
    :arith_op_kw_only,
    ignore(whitespace)
    |> concat(arithmetic_operator)
    |> optional(parsec(:arith_op_kw_only))
  )

  defcombinatorp(
    :bin_log_op_kw_only,
    ignore(whitespace)
    |> concat(binary_logical_operator)
    |> optional(parsec(:bin_log_op_kw_only))
  )

  defcombinatorp(
    :unary_log_op_kw_only,
    ignore(whitespace)
    |> concat(unary_logical_operator)
    |> optional(parsec(:unary_log_op_kw_only))
  )

  defcombinatorp(
    :comparison_op_kw_only,
    ignore(whitespace)
    |> concat(comparison_operator)
    |> optional(parsec(:comparison_op_kw_only))
  )

  defcombinator(
    :a_word,
    ignore(whitespace)
    |> repeat(ascii_char([?a..?z, ?A..?Z]))
    |> reduce(:make_word)
    |> unwrap_and_tag(:word_decl_name)
  )

  # defcombinator(
  #   :catch_single_char
  # )

  # --------------------------------------------------------
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
    |> optional(parsec(:a_word2))
  )

  defcombinator(
    :stack_op_expression,
    parsec(:maybe_number)
    |> concat(parsec(:parse_stack_keywords))
  )

  defcombinator(
    :comparison_expression,
    optional(parsec(:maybe_number))
    |> concat(parsec(:comparison_op_kw))
  )

  defcombinator(
    :binary_logical_expressions,
    parsec(:maybe_number)
    |> concat(parsec(:binary_logical_op_parse))
  )

  defcombinator(
    :unary_logical_expressions,
    parsec(:maybe_number)
    |> concat(parsec(:unary_logical_op_parse))
  )

  defcombinator(
    :word_expressions_declaration,
    ignore(whitespace)
    |> concat(string(": ") |> replace(:colon_space))
    |> parsec(:a_word)
    |> ignore(whitespace)
    |> concat(parsec(:stack_op_kw_only))
    |> ignore(whitespace)
    |> concat(parsec(:arith_op_kw_only))
    |> ignore(whitespace)
    |> concat(string(";") |> replace(:semicolon))
  )

  defcombinator(
    :word_fn_call,
    ignore(whitespace)
    |> concat(parsec(:maybe_number))
    |> concat(parsec(:a_word2))
  )

  defcombinator(
    :word_expr_using_other_custom_words,
    ignore(whitespace)
    |> concat(string(": ") |> replace(:colon_space))
    |> parsec(:a_word2)
    |> ignore(whitespace)
    |> concat(string(";") |> replace(:semicolon))
  )

  defcombinator(
    :one_for_all,
    choice([
      parsec(:simple_expression) |> tag(:simple_expression),
      parsec(:extended_expression) |> tag(:single_operand_operator_expr),
      parsec(:stack_op_expression) |> tag(:stack_op),
      parsec(:comparison_expression) |> tag(:comparison_op),
      parsec(:binary_logical_expressions) |> tag(:bin_log_op),
      parsec(:unary_logical_expressions) |> tag(:unary_log_op),
      parsec(:word_expressions_declaration) |> tag(:word_expr_decl),
      parsec(:word_fn_call) |> tag(:word_fn_call),
      parsec(:word_expr_using_other_custom_words) |> tag(:word_of_words),
      parsec(:stack_op_kw_only) |> tag(:stack_op_kw_only),
      parsec(:arith_op_kw_only) |> tag(:arith_op_kw_only),
      parsec(:bin_log_op_kw_only) |> tag(:bin_log_op_kw_only),
      parsec(:unary_log_op_kw_only) |> tag(:unary_log_op_kw_only),
      parsec(:comparison_op_kw_only) |> tag(:comparison_op_kw_only),
      parsec(:a_word2) |> tag(:single_word)
      # parsec(:print_statement) |> tag(:print_op)
    ])
  )

  defcombinator(
    :word_expr_syn_error_1,
    ignore(whitespace)
    |> concat(string(":"))
  )

  defcombinator(
    :word_expr_syn_error_2,
    ignore(whitespace)
    |> concat(string(": "))
  )

  defcombinator(
    :word_expr_syn_error_3,
    ignore(whitespace)
    |> concat(string(": "))
  )
end

defmodule ForthInterpreter.EntryPoint do
  @moduledoc """
  Documentation for `ForthInterpreter`.
  """
  import NimbleParsec
  import ForthInterpreter.Helpers
  NimbleParsec.defparsec(:expr, parsec(:one_for_all))
end

defmodule ForthInterpreter.Driver do
  def new(""), do: nil

  def new(input) do
    rest = input |> String.trim() |> String.downcase()
    # try do
    #   {:ok, parsed, rest, _, _, _} = ForthInterpreter.EntryPoint.expr(rest)
    #   [parsed | new(rest)]
    # catch
    #   x -> "Caught: #{x}"
    # end
    # IO.puts("REST => #{String.length(rest)}")
    # {:ok, parsed, rest, _, _, _} = ForthInterpreter.EntryPoint.expr(rest)
    # IO.puts("REST => #{rest}")

    # {:ok, parsed, rest, _, _, _} = ForthInterpreter.EntryPoint.expr(rest)
    # [parsed | new(rest)]

    case ForthInterpreter.EntryPoint.expr(rest) do
      {:ok, parsed, rest, _, _, _} ->
        case new(rest) do
          {:error, reason} -> {:error, reason}
          _ -> [parsed | new(rest)]
        end

      # [parsed | new(rest)]

      {:error, _parsed, rest, _ctx_map, _offset, _second_offset} ->
        # IO.puts("Parsed Val #{parsed}")
        # IO.puts("Rest = #{rest}")
        IO.puts("REST IS HERE->#{input}")
        {:error, error_str} = Error.SyntaxError.check_syn_err_for_word_def(input)
        # IO.puts("OUT THERE -> #{error_str}")
        {:error, error_str}
    end
  end
end
