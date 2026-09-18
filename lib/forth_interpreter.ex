defmodule ForthInterpreter do
  @moduledoc """
  Documentation for `ForthInterpreter`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ForthInterpreter.hello()
      :world

  """
  import NimbleParsec

  def new(input) do
    IO.puts("#{input}")
  end

  defp parser(input) do
    new_input = "5 4 +"
  end

end
