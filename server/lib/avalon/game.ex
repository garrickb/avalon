defmodule Avalon.Game do

  @enforce_keys [:name]
  defstruct [name: nil, players: nil, king: nil, state: nil]

  alias Avalon.Game
  alias Avalon.FsmGameState, as: State
  alias Avalon.Player, as: Player

  require Logger

  @doc """
  Creates a new game.
  """
  def new(name, players) do
    players_and_roles = Player.newFromList(players, get_role_list(length players))
    Logger.info("Created new game: #{inspect(players_and_roles)}")

    %Game{name: name,
          players: players_and_roles,
          king: (:rand.uniform(length players) - 1),
          state: State.new
        }
  end

  def summary(game, player_name) do
    game
  end

  defp get_role_list(size) do
    Enum.map(0..(size - 1), fn x -> if x < number_of_evil(size), do: :evil, else: :good end)
  end

  defp number_of_evil(size) when is_number(size) do
    case size do
        5 -> 2
        6 -> 2
        7 -> 3
        8 -> 3
        9 -> 3
        10 -> 4
        _ -> 1
    end
  end
end
