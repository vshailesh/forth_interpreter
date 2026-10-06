defmodule Forth.Forth do
  import ForthInterpreter.Driver
  import Forth.Stack
  alias Forth.Stack

  defp perform([], stack, word_map), do: stack
  defp perform(nil, stack, word_map), do: stack

  defp perform([h | tail], stack, word_map) do
    [first_expr | other_expr] = h
    {expr_type, rest_expr} = first_expr

    output_stack =
      case expr_type do
        :simple_expression ->
          process_simple_expression(rest_expr, stack, word_map)

        :single_operand_operator_expr ->
          process_single_operand_operator_expr(rest_expr, stack, word_map)

        :stack_op ->
          process_stack_op(rest_expr, stack, word_map)

        :stack_op_kw_only ->
          process_stack_op_kw_only(rest_expr, stack, word_map)

        :comparison_op ->
          process_comparison_op(rest_expr, stack, word_map)

        :comparison_op_kw_only ->
          process_comparison_op(rest_expr, stack, word_map)

        :bin_log_op ->
          process_binary_logical_expr(rest_expr, stack, word_map)

        :unary_log_op ->
          process_unary_log_expr(rest_expr, stack, word_map)

        :arith_op_kw_only ->
          process_arith_kw_only_expr(rest_expr, stack, word_map)

        :bin_log_op_kw_only ->
          process_binary_logical_expr(rest_expr, stack, word_map)

        :unary_log_op_kw_only ->
          process_unary_log_expr(rest_expr, stack, word_map)

        :just_input_numbers ->
          process_just_input_numbers(rest_expr, stack, word_map)

        :word_expr_decl ->
          []

        :word_of_words ->
          []

        :word_fn_call ->
          process_word_fn_call(rest_expr, stack, word_map)

        :simple_expr2 ->
          process_simple_expr2(rest_expr, stack, word_map)

        :single_word ->
          process_single_word(rest_expr, stack, word_map)
      end

    perform(tail, output_stack, word_map)
  end

  defp process_single_word(rest_expr, stack, word_map) do
    [{:fn_name, name}] = rest_expr
    opr_kwl = word_map[name]

    case opr_kwl do
      nil ->
        {:error, "unknown word: #{name}"}

      _ ->
        execute_operation_list(opr_kwl, stack, word_map)
    end

    # IO.inspect(opr_kwl)
  end

  defp process_simple_expr2([], stack, word_map), do: stack

  defp process_simple_expr2([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :n_op_expr ->
          process_N_op_expr(val2, stack, word_map)
      end

    process_simple_expr2(tail, output_stack, word_map)
  end

  defp process_N_op_expr(n_op_expr, stack, word_map) do
    [first_element | [last_element]] = n_op_expr
    {:number, num} = first_element
    {:op, op_type} = last_element

    case op_type do
      :dup ->
        res = process_n_op_dup(num, stack)
        res

      :drop ->
        process_n_op_drop(num, stack)

      :swap ->
        process_n_op_swap(num, stack)

      :over ->
        process_n_op_over(num, stack)
    end
  end

  defp process_n_op_over_helper(0, stack, pair), do: pair

  defp process_n_op_over_helper(num, stack, pair) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            process_n_op_over_helper(num - 1, tail2, [val1, val2])
        end
    end
  end

  defp process_n_op_over(num, stack) do
    pair_for_over_op = process_n_op_over_helper(num, stack, [])
    List.flatten([pair_for_over_op | stack])
  end

  defp process_n_op_swap_helper(0, stack, acc), do: {acc, stack}

  defp process_n_op_swap_helper(num, stack, acc) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            process_n_op_swap_helper(num - 1, tail2, [[val1, val2] | acc])
        end
    end
  end

  defp process_n_op_swap(num, stack) do
    {all_the_pairs_to_be_swapped, ret_stack} = process_n_op_swap_helper(num, stack, [])
    List.flatten([all_the_pairs_to_be_swapped | ret_stack])
  end

  defp process_n_op_drop(num, []), do: []
  defp process_n_op_drop(0, stack), do: stack

  defp process_n_op_drop(num, stack) do
    {head, tail} = Stack.pop(stack)
    process_n_op_drop(num - 1, tail)
  end

  defp process_n_op_dup_helper(0, stack), do: []

  defp process_n_op_dup_helper(num, stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        [val1 | process_n_op_dup_helper(num - 1, tail1)]
    end
  end

  defp process_n_op_dup(num, stack) do
    to_be_duped = process_n_op_dup_helper(num, stack)
    merge_two_lists(Stack.reverse(to_be_duped), stack)
  end

  defp merge_two_lists([], stack), do: stack

  defp merge_two_lists([head | tail], acc) do
    merge_two_lists(tail, [head | acc])
  end

  defp process_word_fn_call(expr, stack, word_map) do
    final_operation_list = build_operation_list(expr, word_map)
    final_operation_list = List.flatten(final_operation_list)
    execute_operation_list(final_operation_list, stack, word_map)
  end

  defp build_operation_list_helper([], word_map, acc), do: acc

  defp build_operation_list_helper([head | tail], word_map, acc) do
    {val1, val2} = head

    new_list =
      case val1 do
        :fn_name ->
          [word_map[val2] | acc]

        _ ->
          [head | acc]
      end

    build_operation_list_helper(tail, word_map, new_list)
  end

  defp build_operation_list(expr, word_map) do
    opr_list = build_operation_list_helper(expr, word_map, [])
    opr_list2 = Stack.reverse(opr_list)
    opr_list2
  end

  defp execute_operation_list([], stack, word_map), do: stack

  defp execute_operation_list([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :addition ->
              perform_addition(stack)

            :subtraction ->
              perform_subtraction(stack)

            :multiplication ->
              perform_multiplication(stack)

            :division ->
              perform_division(stack)

            :mod ->
              perform_modulo(stack)

            :dup ->
              perform_dup(stack)

            :drop ->
              perform_drop(stack)

            :swap ->
              perform_swap(stack)

            :over ->
              perform_over(stack)

            :rot ->
              perform_rot(stack)

            :nip ->
              perform_nip(stack)

            :tuck ->
              perform_tuck(stack)

            :and ->
              process_logical_and(stack)

            :or ->
              process_logical_or(stack)

            :not ->
              process_not_opr(stack)

            :invert ->
              process_invert_opr(stack)

            :eq ->
              process_equality(stack)

            :gt ->
              process_greater_than(stack)

            :lt ->
              process_less_than(stack)
          end
      end

    case output_stack do
      {:error, reason} ->
        {:error, reason}

      _ ->
        execute_operation_list(tail, output_stack, word_map)
    end
  end

  defp process_just_input_numbers([], stack, word_map), do: stack

  defp process_just_input_numbers([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)
      end

    process_just_input_numbers(tail, output_stack, word_map)
  end

  defp process_bin_log_kw_only([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :op ->
          case val2 do
            :addition -> perform_addition(stack)
            :subtraction -> perform_subtraction(stack)
            :division -> perform_division(stack)
            :multiplication -> perform_multiplication(stack)
            :mod -> perform_modulo(stack)
          end
      end

    process_bin_log_kw_only(tail, output_stack, word_map)
  end

  defp process_arith_kw_only_expr([], stack, word_map), do: stack
  defp process_arith_kw_only_expr(rest_expr, [], word_map), do: {:error, "stack underflow"}

  defp process_arith_kw_only_expr([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :op ->
          case val2 do
            :addition -> perform_addition(stack)
            :subtraction -> perform_subtraction(stack)
            :division -> perform_division(stack)
            :multiplication -> perform_multiplication(stack)
            :mod -> perform_modulo(stack)
          end
      end

    process_arith_kw_only_expr(tail, output_stack, word_map)
  end

  defp process_unary_log_expr([], stack, word_map), do: stack

  defp process_unary_log_expr([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :not ->
              process_not_opr(stack)

            :invert ->
              process_invert_opr(stack)
          end
      end

    case output_stack do
      {:error, reason} -> {:error, reason}
      output_stack -> process_unary_log_expr(tail, output_stack, word_map)
    end
  end

  defp process_invert_opr([]), do: {:error, "stack underflow"}

  defp process_invert_opr(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        [Bitwise.bnot(val1)]
    end
  end

  defp process_not_opr([]), do: {:error, "stack underflow"}

  defp process_not_opr(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        if val1 == 0 do
          [-1]
        else
          if val1 != 0 do
            [0]
          end
        end
    end
  end

  defp process_binary_logical_expr([], stack, word_map), do: stack

  defp process_binary_logical_expr([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :and ->
              process_logical_and(stack)

            :or ->
              process_logical_or(stack)
          end
      end

    case output_stack do
      {:error, reason} ->
        {:error, reason}

      out_stack ->
        process_binary_logical_expr(tail, out_stack, word_map)
    end
  end

  defp process_logical_or(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            v1 =
              if val1 <= -1 do
                true
              else
                false
              end

            v2 =
              if val2 <= -1 do
                true
              else
                false
              end

            if v1 or v2 do
              [-1]
            else
              [0]
            end
        end
    end
  end

  defp process_logical_and([]), do: {:error, "stack underflow"}

  defp process_logical_and(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            v1 =
              if val1 <= -1 do
                true
              else
                false
              end

            v2 =
              if val2 <= -1 do
                true
              else
                false
              end

            if v1 and v2 do
              [-1]
            else
              [0]
            end
        end
    end
  end

  defp process_comparison_op([], stack, word_map), do: stack

  defp process_comparison_op([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :eq -> process_equality(stack)
            :gt -> process_greater_than(stack)
            :lt -> process_less_than(stack)
          end
      end

    case output_stack do
      {:error, reason} ->
        {:error, reason}

      out_stack ->
        process_comparison_op(tail, out_stack, word_map)
    end
  end

  defp process_less_than([]), do: {:error, "stack underflow"}

  defp process_less_than(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            if val2 < val1 do
              [-1]
            else
              [0]
            end
        end
    end
  end

  defp process_greater_than([]), do: {:error, "stack underflow"}

  defp process_greater_than(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            if val2 > val1 do
              [-1]
            else
              [0]
            end
        end
    end
  end

  defp process_equality([]), do: {:error, "stack underflow"}

  defp process_equality(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            if val1 == val2 do
              [-1]
            else
              [0]
            end
        end
    end
  end

  defp process_stack_op_kw_only([], stack, word_map), do: stack
  defp process_stack_op_kw_only([], [], word_map), do: {:error, "stack underflow"}

  defp process_stack_op_kw_only([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :op ->
          case val2 do
            :dup -> perform_dup(stack)
            :drop -> perform_drop(stack)
            :swap -> perform_swap(stack)
            :over -> perform_over(stack)
            :rot -> perform_rot(stack)
            :nip -> perform_nip(stack)
            :tuck -> perform_tuck(stack)
          end
      end

    case output_stack do
      {:error, reason} -> {:error, reason}
      res_stack -> process_stack_op_kw_only(tail, res_stack, word_map)
    end
  end

  # defp process_stack_op([], [], word_map), do: {:error, "stack underflow"}
  # defp process_stack_op(rest_expr, [], word_map), do: []
  defp process_stack_op([], stack, word_map), do: stack

  defp process_stack_op([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :dup -> perform_dup(stack)
            :drop -> perform_drop(stack)
            :swap -> perform_swap(stack)
            :over -> perform_over(stack)
            :rot -> perform_rot(stack)
            :nip -> perform_nip(stack)
            :tuck -> perform_tuck(stack)
          end
      end

    process_stack_op(tail, output_stack, word_map)
  end

  defp perform_tuck([]), do: {:error, "stack underflow"}

  defp perform_tuck(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} -> {:error, reason}
          {val2, tail2} -> [val1, val2, val1 | tail2]
        end
    end
  end

  defp perform_nip([]), do: {:error, "stack underflow"}

  defp perform_nip(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail1} ->
        case Stack.pop(tail1) do
          {:error, reason} -> {:error, reason}
          {val2, tail2} -> [val1 | tail2]
        end
    end
  end

  defp perform_rot([]), do: {:error, "stack underflow"}

  defp perform_rot(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail} ->
        case Stack.pop(tail) do
          {:error, reason} ->
            {:error, reason}

          {val2, tail2} ->
            case Stack.pop(tail2) do
              {:error, reason} -> {:error, reason}
              {val3, tail3} -> [val3, val1, val2 | tail3]
            end
        end
    end
  end

  defp perform_over([]), do: {:error, "stack underflow"}

  defp perform_over(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail} ->
        case Stack.pop(tail) do
          {:error, reason} -> {:error, reason}
          {val2, tail2} -> [val2, val1 | tail]
        end
    end
  end

  defp perform_swap([]), do: {:error, "stack underflow"}

  defp perform_swap(stack) do
    case Stack.pop(stack) do
      {:error, reason} ->
        {:error, reason}

      {val1, tail} ->
        case Stack.pop(tail) do
          {:error, reason} -> {:error, reason}
          {val2, tail2} -> [val2, val1 | tail2]
        end
    end
  end

  defp perform_drop([]), do: {:error, "stack underflow"}

  defp perform_drop(stack) do
    {head, tail} = Stack.pop(stack)
    tail
  end

  defp perform_dup([]), do: {:error, "stack underflow"}

  defp perform_dup(stack) do
    {head, original_stack} = Stack.peek(stack)
    [head | stack]
  end

  defp process_single_operand_operator_expr(rest_expr, [], word_map),
    do: {:error, "stack underflow"}

  defp process_single_operand_operator_expr([], stack, word_map), do: stack

  defp process_single_operand_operator_expr([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :addition -> perform_addition(stack)
            :subtraction -> perform_subtraction(stack)
            :division -> perform_division(stack)
            :multiplication -> perform_multiplication(stack)
            :mod -> perform_modulo(stack)
          end
      end

    process_single_operand_operator_expr(tail, output_stack, word_map)
  end

  defp process_simple_expression([], stack, word_map), do: stack

  defp process_simple_expression([head | tail], stack, word_map) do
    {val1, val2} = head

    output_stack =
      case val1 do
        :number ->
          Stack.push(val2, stack)

        :op ->
          case val2 do
            :addition -> perform_addition(stack)
            :subtraction -> perform_subtraction(stack)
            :division -> perform_division(stack)
            :multiplication -> perform_multiplication(stack)
            :mod -> perform_modulo(stack)
          end
      end

    process_simple_expression(tail, output_stack, word_map)
  end

  defp perform_addition(stack) do
    {opr1, rest} = Stack.pop(stack)
    {opr2, rest} = Stack.pop(rest)
    result = opr2 + opr1
    Stack.push(result, rest)
  end

  defp perform_subtraction(stack) do
    {opr1, rest} = Stack.pop(stack)
    {opr2, rest} = Stack.pop(rest)
    result = opr2 - opr1
    Stack.push(result, rest)
  end

  defp perform_division(stack) do
    {opr1, rest} = Stack.pop(stack)
    {opr2, rest} = Stack.pop(rest)

    if opr1 == 0 do
      {:error, "division by zero"}
    else
      result = div(opr2, opr1)
      Stack.push(result, rest)
    end
  end

  defp perform_multiplication(stack) do
    {opr1, rest} = Stack.pop(stack)
    {opr2, rest} = Stack.pop(rest)
    result = opr2 * opr1
    Stack.push(result, rest)
  end

  defp perform_modulo(stack) do
    {opr1, rest} = Stack.pop(stack)
    {opr2, rest} = Stack.pop(rest)
    result = Integer.mod(opr2, opr1)
    Stack.push(result, rest)
  end

  defp get_opr_kwl_helper([], opr_kwl), do: opr_kwl

  defp get_opr_kwl_helper([head | tail], opr_kwl) do
    case head do
      :semicolon -> opr_kwl
      _ -> get_opr_kwl_helper(tail, [head | opr_kwl])
    end
  end

  defp get_opr_kwl(expr) do
    get_opr_kwl_helper(expr, [])
  end

  defp build_word_map_helper(expr) do
    [:colon_space, word_name_tup | tail] = expr
    operation_kwl = get_opr_kwl(tail)
    {word_name_key, word_name_value} = word_name_tup
    %{{word_name_value, Stack.reverse(operation_kwl)}}
  end

  defp build_word_map(nil, word_map), do: word_map
  defp build_word_map([], word_map), do: word_map

  defp build_word_map([head | tail], word_map) do
    [finhead] = head
    {expr_type, rest_expr} = finhead

    wm =
      case expr_type do
        :word_expr_decl ->
          build_word_map_helper(rest_expr)

        _ ->
          %{}
      end

    build_word_map(tail, Map.merge(word_map, wm))
  end

  defp create_opr_kwl_helper([], word_map, opr_kwl), do: opr_kwl

  defp create_opr_kwl_helper([head | tail], word_map, opr_kwl) do
    case head do
      :semicolon ->
        opr_kwl

      {:fn_name, name} ->
        fn_expr_list = word_map[name]

        case fn_expr_list do
          nil ->
            {:error, "unknown word: invalid"}

          some_expr ->
            create_opr_kwl_helper(tail, word_map, [some_expr | opr_kwl])
        end

      _ ->
        create_opr_kwl_helper(tail, word_map, [head | opr_kwl])
    end
  end

  defp create_opr_kwl(expr, word_map) do
    create_opr_kwl_helper(expr, word_map, [])
  end

  defp build_word_map_from_word_of_words_expr(expr, word_map) do
    [:colon_space, word_name_tup | tail] = expr
    operation_kwl = create_opr_kwl(tail, word_map)
    {word_name_key, word_name_value} = word_name_tup
    %{{word_name_value, List.flatten(Stack.reverse(operation_kwl))}}
  end

  defp build_word_map_from_word_of_words(nil, word_map), do: word_map
  defp build_word_map_from_word_of_words([], word_map), do: word_map

  defp build_word_map_from_word_of_words([head | tail], word_map) do
    [finhead] = head
    {expr_type, rest_expr} = finhead

    wm =
      case expr_type do
        :word_of_words ->
          build_word_map_from_word_of_words_expr(rest_expr, word_map)

        _ ->
          %{}
      end

    build_word_map_from_word_of_words(tail, Map.merge(word_map, wm))
  end

  def get_next([h | t]), do: {h, t}

  def eval(str_input, init_stack) do
    parsed_input = ForthInterpreter.Driver.new(str_input)

    case parsed_input do
      {:error, reason} ->
        {:error, reason}

      _ ->
        stack = Stack.new(init_stack)
        word_map = build_word_map(parsed_input, %{})
        word_map2 = build_word_map_from_word_of_words(parsed_input, word_map)

        case perform(parsed_input, stack, word_map2) do
          {:error, reason} ->
            {:error, reason}

          final_stack ->
            {:ok, Stack.reverse(final_stack)}
        end
    end
  end

  def eval(str_input) do
    eval(str_input, [])
  end
end
