defmodule Avalon.Player do

  @enforce_keys [:name, :role]
  defstruct [name: nil, role: nil]

  alias Avalon.Player

  require Logger

  @doc """
  Creates a list of players with random roles.
  """
  def newFromList(names, roles) do
    Stream.zip(names, Enum.shuffle roles) |> Enum.map(fn {n, r} -> %Player{name: n, role: r} end)
  end

  @doc """
  Creates a new player.
  """
  def new(name, role) do
    %Player{name: name,
            role: role
          }
  end
end
