defmodule Avalon.Game do

  @enforce_keys [:name]
  defstruct [:name, :players, :fsm ]

  alias Avalon.Game
  alias Avalon.FsmGameState, as: GameState
  alias Avalon.Player, as: Player

  require Logger

  @doc """
  Creates a new game.
  """
  def new(name, players) when is_binary(name) and is_list(players) do
    players_and_roles = Player.newFromList(players, get_role_list(length players))

    game = %Game{ name: name,
                  players: players_and_roles |> set_random_king,
                  fsm: GameState.new
                }

    Logger.info("Created new game: #{inspect(game)}")
    game
  end

  @doc """
  Mark a player as ready when the game is in :waiting state
  if all players are ready, then advance the game.
  """
  def set_player_ready(game, player_name) when is_binary(player_name) do
    Logger.info("Marking #{player_name}")
    if state(game) != :waiting do
      Logger.error("Attempted to mark a player as ready when not in waiting state.")
      {:error, "need to be in waiting state to be ready"}
    end

    # If all players are ready, then we can start the game!
    new_players = Enum.map(game.players, fn p -> (if p.name == player_name, do: %{p | ready: true}, else: p) end )
    fsm =
      if all_players_ready?(new_players) do
        Logger.info("Game #{game.name} has all players ready. Starting game!")
        GameState.start_game(game.fsm)
      else game.fsm end

    %{game | players: new_players, fsm: fsm}
  end

  def all_players_ready?(players) do
    players |> Enum.all?(fn p -> p.ready == true end)
  end

  # defp get_player(game, player_name) when is_binary(player_name) do
  #   Enum.find(game.players, fn p -> p.name == player_name end)
  # end

  defp state(game) do
    game.fsm.state
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

  # defp set_no_king(players) do
  #   players |> Enum.map(fn p -> {p | king: false} end)
  # end

  defp set_random_king(players) do
    king = Enum.random(players)
    players |> Enum.map(fn p -> %{p | king: (p == king)} end)
  end
end
