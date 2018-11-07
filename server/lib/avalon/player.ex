defmodule Avalon.Player do

  @enforce_keys [:name, :role]
  defstruct [:name, :role, :ready, :king]

  alias Avalon.Player

  require Logger

  @doc """
  Creates a list of players with random roles.
  """
  def newFromList(names, roles) when is_list(names) and is_list(roles) do
    Stream.zip(names, Enum.shuffle roles) |> Enum.map(fn {n, r} -> new(n, r) end)
  end

  @doc """
  Creates a new player.
  """
  def new(name, role) when is_binary(name) and is_atom(role) do
    %Player{name: name,
            role: role,
            ready: false,
            king: false
          }
  end
end
