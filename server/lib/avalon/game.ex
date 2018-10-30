defmodule Avalon.Game do

  @enforce_keys [:name]
  defstruct name: nil, players: 0

  alias Avalon.Game

  @doc """
  Creates a game.
  """
  def new(name) do
    %Game{name: name}
  end
end
