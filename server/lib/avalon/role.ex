defmodule Avalon.Role do
  @enforce_keys [:name, :alignment]
  defstruct [:name, :alignment]

  alias Avalon.Role

  require Logger

  @doc """
  Creates a new role.
  """
  def new(name) when is_atom(name) do
    %Role{name: name, alignment: get_alignment(name)}
  end

  defp get_alignment(name) do
    case name do
      :merlin ->
        :good

      :assassin ->
        :evil

      :percival ->
        :good

      :mordred ->
        :evil

      :oberon ->
        :evil

      :morgana ->
        :evil

      :servant ->
        :good

      :minion ->
        :evil
    end
  end

  def pad(roles, num_evil, num_good) when is_number(num_evil) and is_number(num_good) do
    evil =
      roles
      |> Enum.filter(fn role -> role.alignment == :evil end)
      |> Enum.slice(0, num_evil)

    padded_evil =
      if num_evil > length(evil) do
        evil ++ Enum.map(length(evil)..(num_evil - 1), fn _ -> Role.new(:minion) end)
      else
        evil
      end

    good =
      roles
      |> Enum.filter(fn role -> role.alignment == :good end)
      |> Enum.slice(0, num_good)

    padded_good =
      if num_good > length(good) do
        good ++ Enum.map(length(good)..(num_good - 1), fn _ -> Role.new(:servant) end)
      else
        good
      end

    padded_evil ++ padded_good
  end
end
