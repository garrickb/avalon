defmodule Avalon.Game do

  @enforce_keys [:name]
  defstruct [:name, :players, :king, :state ]

  alias Avalon.Game
  alias Avalon.FsmGameState, as: State
  alias Avalon.Player, as: Player

  require Logger

  @doc """
  Creates a new game.
  """
  def new(name, players) when is_binary(name) and is_list(players) do
    players_and_roles = Player.newFromList(players, get_role_list(length players))

    game = %Game{name: name,
                  players: players_and_roles,
                  king: (:rand.uniform(length players) - 1),
                  state: State.new
                }

    Logger.info("Created new game: #{inspect(game)}")
    game
  end

  @doc """
  Mark a player as ready when the game is in :waiting state
  """
  def player_ready(game) do
    if state(game) != :waiting do
      {:error, "need to be in waiting state"}
    end
    game
  end

  defp state(game) do
    game.state.state
  end

  defp get_role_list(size) when is_number(size) do
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
        _ -> if size < 5, do: 1, else: 4
    end
  end
end
