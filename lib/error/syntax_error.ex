defmodule Error.SyntaxError do
  # list_of_stack_operators = ["+", ]

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
      # IO.puts("Reaching Here #{input}")

      # with {:ok, term, rest} <- choice([digit_followed_by_ascii_chars(), some_stack_operator()]).(input) do
      #   # IO.puts("From withing WITH #{term}")
      #   input2 = rest

      #   # check for ?\s?; codepoint or single ?; codepoint
      #   # terminate if any one of the 2 conditions meet
      #   # this acts as a sort of lookahead function
      #   with {:ok, term1, rest1} <- char().(input2), {:ok, term2, _rest2} <- char().(rest1) do
      #     if term1 == ?\s and term2 == ?; do
      #       # IO.puts("Detecting space and semicolon")
      #       # IO.puts("#{rest}")
      #       {:ok, term, rest}
      #     else
      #       # if no \s; or ; term is found then continue to parse
      #       either_func_call_or_stack_operation().(rest)
      #     end
      #   else
      #     # {:error, _reason} -> {:error, "end of string, in search of <space>;"}
      #     {:error, _reason} -> {:error, "unterminated definition"}
      #   end
      # else
      #   {:error, _reason} ->
      #     {:error, "The choice is failing why ?"}
      # end

      # choice([digit_followed_by_ascii_chars(), some_stack_operator()]).(input)

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

  # defp digit_followed_by_ascii_chars() do
  #   fn input ->
  #     many(sequence([many(digit()), word_name_identifier_char()]))
  #     |> map(fn {:ok, [chars], _rest} -> to_string(chars) end)
  #   end
  # end

  # defp to_check_the_input_passed_down() do
  #   fn input ->
  #     IO.puts("THE PASSED DOWN INPUT ===> #{input}")
  #   end
  # end

  defp digit(), do: satisfy(char(), fn ch -> ch in ?0..?9 end)
  defp ascii_letter(), do: satisfy(char(), fn ch -> ch in ?a..?z or ch in ?A..?Z end)

  defp arithmetic_operator(),
    do: satisfy(char(), fn ch -> ch == ?+ or ch == ?- or ch == ?* or ch == ?/ end)

  # defp identifier_char(), do: choice([ascii_letter(), char(?_), digit()])
  # defp word_name_identifier(), do: choice([ascii_letter(), char(?_)])

  defp word_name_identifier_char() do
    satisfy(
      many(choice([ascii_letter(), char(?_)])),
      fn chars -> chars != [] end
    )
  end

  # defp identifier() do
  #   map(
  #     satisfy(many(identifier_char()), fn chars -> chars != [] end),
  #     fn chars -> to_string(chars) end
  #   )
  # end

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

  # defp token(parser) do
  #   sequence([
  #     many(choice([char(?\s), char(?\n)])),
  #     parser,
  #     many(choice([char(?\s), char(?\n)]))
  #   ])
  #   |> map(fn [_lw, term, _tw] -> term end)
  # end

  defp token2(parser) do
    sequence([
      many(choice([char(?\s), char(?\n)])),
      parser
    ])
    |> map(fn [_lw, term] -> term end)
  end

  # defp convert_digit_followed_by_ascii_letter_to_string() do
  # end

  # defp dfbac_helper("") do
  #   {:error, "unexpected end of string"}
  # end

  # defp dfbac_helper(input) do
  #   with {:ok, term, rest} <- many(sequence([many(digit()), word_name_identifier_char()])).(input) do
  #     # IO.puts("#{rest}")
  #     dfbac_helper(rest)
  #   end
  # end

  # defp digit_followed_by_ascii_chars() do
  #   fn input ->
  #     IO.puts("DIGIT #{input}")
  #     with {:ok, term, rest} <- sequence([whitespaces(), many(digit()), word_name()]).(input) do
  #       input2 = rest
  #       with {:ok, term1, rest1} <- char().(input2), {:ok, term2, _rest2} <- char().(rest1) do
  #         if term1 == ?\s and term2 == ?; do
  #           IO.puts("REST #{rest}")
  #           {:ok, term, rest}
  #         else
  #           digit_followed_by_ascii_chars().(rest)
  #         end
  #       else
  #         {:error, _reason} -> {:error, "unterminated definition"}
  #       end

  #       # digit_followed_by_ascii_chars().(rest)
  #       # case rest do
  #       #   "" -> {:error, "End of input"}
  #       #   _ -> digit_followed_by_ascii_chars().(rest)
  #       # end
  #     else
  #       {:error, reason} ->
  #         IO.puts("INPUT=#{input}")
  #         IO.puts("REASON DIGIT#{reason}")
  #         {:error, "Failed for some reason not sure why"}
  #     end
  #   end
  # end

  defp digit_followed_by_ascii_chars() do
    fn input ->
      with {:ok, term, rest} <- sequence([whitespaces(), many(digit()), word_name()]).(input) do
        # IO.puts("digit #{rest}")
        {:ok, term, rest}
      else
        {:error, _reason} -> {:error, "Failing in digit func"}
      end
    end
  end

  # defp some_stack_operator() do
  #   fn input ->
  #     with {:ok, term, rest} <- sequence([whitespaces(), arithmetic_operator()]).(input) do
  #       IO.puts("STACK #{input}")
  #       # input2 = rest
  #       # with {:ok, term1, rest1} <- char().(input2), {:ok, term2, _rest2} <- char().(rest1) do
  #       #   if term1 == ?\s and term2 == ?; do
  #       #     IO.puts("REST #{rest}")
  #       #     {:ok, term, rest}
  #       #   else
  #       #     some_stack_operator().(rest)
  #       #   end
  #       # else
  #       #   {:error, _reason} -> {:error, "unterminated definition"}
  #       # end

  #       some_stack_operator().(rest)

  #       # case rest do
  #       #   "" -> {:error, "End of input"}
  #       #   _ -> digit_followed_by_ascii_chars().(rest)
  #       # end

  #     else
  #       {:error, reason} ->
  #         IO.puts("INPUT=#{input}")
  #         IO.puts("REASON ST OPR#{reason}")
  #         {:error, "Failed for some reason not sure why"}
  #     end
  #   end
  # end

  defp some_stack_operator() do
    fn input ->
      with {:ok, term, rest} <- sequence([whitespaces(), arithmetic_operator()]).(input) do
        # IO.puts("Stack #{rest}")
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
        # IO.puts("Failing ON =>#{input}")
        # {:error, "word name is not appropriate"}
        {:error, "invalid word definition"}
      end
    end
  end

  defp missing_termination_semicolon() do
    fn input ->
      # IO.puts("Missing Termination Semicolon INPUT ->#{input}")
      with {:ok, term, rest} <- char().(input),
           {:ok, term1, rest1} <- char().(rest) do
        if term == ?\s and term1 == ?; do
          # IO.puts("Ever here")
          {:ok, [term | term1], rest1}
        else
          if term == ?; do
            # IO.puts("H1 #{term}")
            {:error, "unterminated definition"}
          else
            missing_termination_semicolon().(rest)
          end
        end
      else
        {:error, _reason} ->
          # IO.puts("H2 EOS")
          {:error, "unterminated definition"}
      end
    end
  end

  # defp to_check_the_input_passed_down() do
  #   fn input ->
  #     IO.puts("THE PASSED DOWN INPUT ===> #{input}")
  #   end
  # end

  def check_syn_err_for_word_def(input) do
    # check if colon begins the statement
    choice2([
      begins_with_colon(),
      space_after_colon(),
      word_name(),
      either_func_call_or_stack_operation(),
      missing_termination_semicolon()
      # to_check_the_input_passed_down()
      # digit_followed_by_ascii_chars()
    ]).(input)

    # digit_followed_by_ascii_chars().(input)
    # either_func_call_or_stack_operation().(input)
    # some_stack_operator().(input)
    # word_name().(input)
    # missing_termination_semicolon().(input)
  end
end
