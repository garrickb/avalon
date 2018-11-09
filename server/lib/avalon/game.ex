defmodule Avalon.Game do
  @enforce_keys [:name, :fsm]
  defstruct [:name, :players, :quests, :fsm]

  alias Avalon.Game
  alias Avalon.FsmGameState, as: GameState
  alias Avalon.Player, as: Player
  alias Avalon.Quest, as: Quest

  require Logger

  @doc """
  Creates a new game.
  """
  def new(name, players) when is_binary(name) and is_list(players) do
    players_and_roles = Player.newFromList(players, Enum.shuffle(get_role_list(length(players))))

    game = %Game{
      name: name,
      players: players_and_roles |> set_random_king,
      quests: Quest.get_quests(length(players)),
      fsm: GameState.new()
    }

    Logger.info("Created new game: #{inspect(game)}")
    game
  end

  @doc """
  Mark a player as ready when the game is in :waiting state
  if all players are ready, then advance the game.
  """
  def set_player_ready(game, player_name) when is_binary(player_name) do
    if game.fsm.state != :waiting do
      Logger.warn("Attempted to mark a player as ready while not in waiting state.")
      game
    else
      # If all players are ready, then we can start the game!
      new_players =
        Enum.map(game.players, fn p -> if p.name == player_name, do: Player.ready(p), else: p end)

      fsm =
        if Player.all_players_ready?(new_players) do
          Logger.info("Game '#{game.name}' has all players ready; starting the game!")
          GameState.start_game(game.fsm)
        else
          game.fsm
        end

      %{game | players: new_players, fsm: fsm}
    end
  end

  @doc """
  select a player to go on a quest
  """
  def select_player(game, player_name) when is_binary(player_name) do
    new_quests =
      Avalon.Quest.get_active_quest(game.quests)
      |> Avalon.Quest.select_player(player_name)
      |> Avalon.Quest.update_quest(game.quests)

    %{game | quests: new_quests}
  end

  @doc """
  deselect a player to go on a quest
  """
  def deselect_player(game, player_name) when is_binary(player_name) do
    new_quests =
      Avalon.Quest.get_active_quest(game.quests)
      |> Avalon.Quest.deselect_player(player_name)
      |> Avalon.Quest.update_quest(game.quests)

    %{game | quests: new_quests}
  end

  @doc """
  begins voting on for the selected quest members for the active quest.
  """
  def begin_voting(game) do
    if game.fsm.state != :select_quest_members do
      Logger.warn("Attempted to begin voting on quest members while not in the proper state.")
      game
    else
      fsm =
        if Quest.get_active_quest(game.quests) |> Quest.voting_can_begin?() do
          Logger.info("Game '#{game.name}' has began voting on active quest")
          GameState.begin_voting(game.fsm)
        else
          Logger.info("Game '#{game.name}' does not have enough players selected to begin voting")
          game.fsm
        end

      %{game | fsm: fsm}
    end
  end

  @doc """
  store a player's vote
  """
  def vote(game, :accept, player_name) when is_binary(player_name) do
    if game.fsm.state != :vote_on_members do
      Logger.warn("Player '#{player_name}' attempted to accept a vote while not in voting state.")
      game
    else
      new_quests =
        game.quests
        |> Avalon.Quest.get_active_quest()
        |> Quest.vote_accept(player_name)
        |> Quest.update_quest(game.quests)

      after_vote(game, new_quests)
    end
  end

  def vote(game, :reject, player_name) when is_binary(player_name) do
    if game.fsm.state != :vote_on_members do
      Logger.warn("Player '#{player_name}' attempted to reject a vote while not in voting state.")
      game
    else
      new_quests =
        game.quests
        |> Avalon.Quest.get_active_quest()
        |> Quest.vote_reject(player_name)
        |> Quest.update_quest(game.quests)

      after_vote(game, new_quests)
    end
  end

  defp after_vote(game, new_quests) do
    active_quest = new_quests |> Avalon.Quest.get_active_quest()

    if active_quest |> Quest.all_players_voted?(length(game.players)) do
      num_rejects = Quest.number_of_reject_votes(active_quest)
      rejects_required = Kernel.map_size(active_quest.votes) / 2

      if num_rejects >= rejects_required do
        # TODO: Store prev votes
        # Clear the vote that after a failure
        quests_after_fail =
          %{active_quest | votes: %{}}
          |> Quest.update_quest(new_quests)

        %{game | quests: quests_after_fail, fsm: GameState.reject(game.fsm)}
      else
        %{game | quests: new_quests, fsm: GameState.accept(game.fsm)}
      end
    else
      %{game | quests: new_quests}
    end
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

  defp set_random_king(players) do
    king = Enum.random(players)
    players |> Enum.map(fn p -> %{p | king: p == king} end)
  end
end
