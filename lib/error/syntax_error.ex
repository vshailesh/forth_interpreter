defmodule Error.SyntaxError do
  defp char() do
    fn input ->
      case input do
        "" -> {:error, "unexptected end of input"}
        <<char::utf8, rest::binary>> -> {:ok, char, rest}
      end
    end
  end

  defp char(expected) do
    satisfy(char(), fn char -> char == expected end)
  end

  defp choice(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:error, "no parser succeeded"}

        [first_parser | other_parsers] ->
          with {:error, _reason} <- first_parser.(input) do
            choice(other_parsers).(input)
          end
      end
    end
  end

  defp satisfy(parser, acceptor) do
    fn input ->
      with {:ok, term, rest} <- parser.(input) do
        if acceptor.(term) do
          {:ok, term, rest}
        else
          {:error, "term rejected"}
        end
      end
    end
  end

  defp choice2(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:ok, "All parsers succeeded, should not happen"}

        [first_parser | other_parsers] ->
          with {:ok, _terms, rest} <- first_parser.(input) do
            choice2(other_parsers).(rest)
          end
      end
    end
  end

  defp begins_with_colon() do
    fn input ->
      char_ret_val = char().(input)

      case char_ret_val do
        {:ok, term, rest} ->
          if term == ?: do
            {:ok, term, rest}
          else
            # {:error, "colon missing"}
            {:error, "invalid word definition"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp space_after_colon() do
    fn input ->
      char_ret_val = char().(input)

      case char_ret_val do
        {:ok, term, rest} ->
          if term == ?\s do
            {:ok, term, rest}
          else
            # {:error, "please add a space after the colon"}
            {:error, "invalid word definition"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp either_func_call_or_stack_operation() do
    fn input ->

      case digit_followed_by_ascii_chars().(input) do
        {:ok, term, rest} ->
          with {:ok, term1, rest1} <- either_func_call_or_stack_operation().(rest) do
            either_func_call_or_stack_operation().(rest1)
          else
            {:error, _reason} -> {:ok, term, rest}
          end

        {:error, _reason} ->
          with {:ok, term, rest} <- some_stack_operator().(input) do
            with {:ok, term1, rest1} <- either_func_call_or_stack_operation().(rest) do
              either_func_call_or_stack_operation().(rest1)
            else
              {:error, _reason} -> {:ok, term, rest}
            end
          else
            {:error, reason} -> {:ok, "", input}
          end
      end
    end
  end

  defp digit(), do: satisfy(char(), fn ch -> ch in ?0..?9 end)
  defp ascii_letter(), do: satisfy(char(), fn ch -> ch in ?a..?z or ch in ?A..?Z end)

  defp arithmetic_operator(),
    do: satisfy(char(), fn ch -> ch == ?+ or ch == ?- or ch == ?* or ch == ?/ end)

  defp word_name_identifier_char() do
    satisfy(
      many(choice([ascii_letter(), char(?_)])),
      fn chars -> chars != [] end
    )
  end

  defp map(parser, mapper) do
    fn input ->
      with {:ok, term, rest} <- parser.(input) do
        {:ok, mapper.(term), rest}
      end
    end
  end

  defp many(parser) do
    fn input ->
      case parser.(input) do
        {:error, _reason} ->
          {:ok, [], input}

        {:ok, term, rest} ->
          {:ok, other_terms, rest} = many(parser).(rest)
          {:ok, [term | other_terms], rest}
      end
    end
  end

  defp sequence(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:ok, [], input}

        [first_parser | other_parsers] ->
          with {:ok, first_term, rest} <- first_parser.(input),
               {:ok, other_terms, rest} <- sequence(other_parsers).(rest) do
            {:ok, [first_term | other_terms], rest}
          end
      end
    end
  end

  defp token2(parser) do
    sequence([
      many(choice([char(?\s), char(?\n)])),
      parser
    ])
    |> map(fn [_lw, term] -> term end)
  end

  defp digit_followed_by_ascii_chars() do
    fn input ->
      with {:ok, term, rest} <- sequence([whitespaces(), many(digit()), word_name()]).(input) do

        {:ok, term, rest}
      else
        {:error, _reason} -> {:error, "Failing in digit func"}
      end
    end
  end

  defp some_stack_operator() do
    fn input ->
      with {:ok, term, rest} <- sequence([whitespaces(), arithmetic_operator()]).(input) do

        {:ok, term, rest}
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp whitespaces() do
    fn input ->
      many(choice([char(?\s), char(?\n)])).(input)
    end
  end

  defp word_name() do
    fn input ->
      with {:error, _reason} <-
             map(
               word_name_identifier_char(),
               fn chars ->
                 to_string(chars)
               end
             ).(input) do
        # {:error, "word name is not appropriate"}
        {:error, "invalid word definition"}
      end
    end
  end

  defp missing_termination_semicolon() do
    fn input ->
      with {:ok, term, rest} <- char().(input),
           {:ok, term1, rest1} <- char().(rest) do
        if term == ?\s and term1 == ?; do
          {:ok, [term | term1], rest1}
        else
          if term == ?; do
            {:error, "unterminated definition"}
          else
            missing_termination_semicolon().(rest)
          end
        end
      else
        {:error, _reason} ->
          {:error, "unterminated definition"}
      end
    end
  end

  def check_syn_err_for_word_def(input) do
    choice2([
      begins_with_colon(),
      space_after_colon(),
      word_name(),
      either_func_call_or_stack_operation(),
      missing_termination_semicolon()
      # to_check_the_input_passed_down()
      # digit_followed_by_ascii_chars()
    ]).(input)
  end
end
