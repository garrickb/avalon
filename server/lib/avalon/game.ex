defmodule Avalon.Game do

  @enforce_keys [:name]
  defstruct [name: nil, players: nil]

  alias Avalon.Game

  require Logger

  @doc """
  Creates a game with a name of length greater than 0.
  """
  def new(name, players) do
    Logger.info("Newgame")
    %Game{name: name, players: players}
  end
end
