defmodule Avalon.Game do
  @enforce_keys [:fsm]
  defstruct [:players, :num_evil, :quests, :fsm]

  alias Avalon.Game
  alias Avalon.FsmGameState, as: GameState
  alias Avalon.Player, as: Player
  alias Avalon.Quest, as: Quest
  alias Avalon.Settings, as: Settings
  alias Avalon.Role, as: Role

  require Logger

  @doc """
  Creates a new game.
  """
  def new(players, settings) when is_list(players) do
    num_players = length(players)
    num_evil = number_of_evil(num_players)
    num_good = num_players - num_evil

    roles = settings |> Settings.get_roles() |> Role.pad(num_evil, num_good) |> Enum.shuffle()

    players_and_roles = Player.newFromList(players, roles)

    game = %Game{
      players: players_and_roles |> Player.set_random_king(),
      num_evil: num_evil,
      quests: Quest.get_quests(length(players)),
      fsm: GameState.new()
    }

    Logger.info(
      "Created new game with players '#{inspect(players)}' and settings '#{inspect(settings)}'"
    )

    game
  end

  @doc """
  Mark a player as ready when the game is in :waiting state
  if all players are ready, then advance the game.
  """
  def set_player_ready(game, player_name) when is_binary(player_name) do
    if game.fsm.state != :waiting do
      Logger.warn("Attempted to mark a player as ready during wrong phase.")
      game
    else
      # If all players are ready, then we can start the game!
      new_players =
        Enum.map(game.players, fn p -> if p.name == player_name, do: Player.ready(p), else: p end)

      fsm =
        if Player.all_players_ready?(new_players) do
          Logger.info("Game has all players ready; starting the game!")
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
    if game.fsm.state != :build_team do
      Logger.warn("Attempted to begin voting on quest members during wrong phase.")
      game
    else
      fsm =
        if Quest.get_active_quest(game.quests) |> Quest.voting_can_begin?() do
          Logger.info("Game has began voting on active quest")
          GameState.begin_voting(game.fsm)
        else
          Logger.info("Game does not have enough players selected to begin voting")
          game.fsm
        end

      %{game | fsm: fsm}
    end
  end

  @doc """
  store a player's vote
  """
  def vote(game, player_name, :accept) when is_binary(player_name) do
    if game.fsm.state != :team_vote do
      Logger.warn("Player '#{player_name}' attempted to accept a vote during wrong phase.")
      game
    else
      new_quests =
        game.quests
        |> Avalon.Quest.get_active_quest()
        |> Quest.player_accept_vote(player_name)
        |> Quest.update_quest(game.quests)

      after_vote(game, new_quests)
    end
  end

  def vote(game, player_name, :reject) when is_binary(player_name) do
    if game.fsm.state != :team_vote do
      Logger.warn("Player '#{player_name}' attempted to reject a vote during wrong phase.")
      game
    else
      new_quests =
        game.quests
        |> Avalon.Quest.get_active_quest()
        |> Quest.player_reject_vote(player_name)
        |> Quest.update_quest(game.quests)

      after_vote(game, new_quests)
    end
  end

  defp after_vote(game, new_quests) do
    active_quest = new_quests |> Avalon.Quest.get_active_quest()

    if active_quest |> Quest.team_done_voting?(length(game.players)) do
      if active_quest |> Quest.team_voting_passed?() do
        quests_after_finished =
          active_quest
          |> Quest.team_finished(game.players |> Player.get_king() |> Map.get(:name), :accept)
          |> Quest.update_quest(new_quests)

        new_fsm = GameState.accept(game.fsm)
        %{game | quests: quests_after_finished, fsm: new_fsm}
      else
        quests_after_finished =
          active_quest
          |> Quest.team_finished(game.players |> Player.get_king() |> Map.get(:name), :reject)
          |> Quest.update_quest(new_quests)

        new_fsm = GameState.reject(game.fsm)
        new_players = Player.set_next_king(game.players)
        %{game | quests: quests_after_finished, fsm: new_fsm, players: new_players}
      end
    else
      %{game | quests: new_quests}
    end
  end

  @doc """
  store a player's quest card
  """
  def quest_play_card(game, player_name, card) when is_binary(player_name) do
    if game.fsm.state != :quest do
      Logger.warn(
        "Player '#{player_name}' attempted to play a '#{card}' quest card during wrong phase."
      )

      game
    else
      new_quests =
        game.quests
        |> Avalon.Quest.get_active_quest()
        |> Quest.player_quest_card(player_name, card)
        |> Quest.update_quest(game.quests)

      quest_after_card(game, new_quests)
    end
  end

  def assassinate_player(game, player_name) when is_binary(player_name) do
    if game.fsm.state != :game_end_good_assassin do
      Logger.warn("Attempted to assassinate a player during wrong phase #{game.fsm.state}")
      game
    else
      fsm =
        if game.players |> Player.is_merlin?(player_name) do
          GameState.correct_assassination(game.fsm)
        else
          GameState.incorrect_assassination(game.fsm)
        end

      %{game | fsm: fsm}
    end
  end

  defp has_assassin_and_merlin(game) do
    roles = Enum.map(game.players, fn p -> p.role end)

    has_merlin = Enum.member?(roles, Avalon.Role.new(:merlin))
    has_assassin = Enum.member?(roles, Avalon.Role.new(:assassin))

    has_assassin && has_merlin
  end

  defp quest_after_card(game, new_quests) do
    # Since new_quests will have the outcome stored, it will not be considered
    # :uncomplete anymore. Therefore we need to get the active quest from the
    # old game state in order to get the correct quest.
    active_quest =
      game.quests
      |> Avalon.Quest.get_active_quest()

    new_active_quest =
      new_quests
      |> Enum.find(fn q -> q.id == active_quest.id end)

    if new_active_quest |> Quest.quest_done_playing?() do
      if new_active_quest |> Quest.quest_passed?() do
        new_fsm =
          if game |> has_assassin_and_merlin(),
            do: GameState.succeed_with_assassin_and_merlin(game.fsm),
            else: GameState.succeed(game.fsm)

        new_players = Player.set_next_king(game.players)
        %{game | quests: new_quests, fsm: new_fsm, players: new_players}
      else
        new_fsm = GameState.fail(game.fsm)
        new_players = Player.set_next_king(game.players)
        %{game | quests: new_quests, fsm: new_fsm, players: new_players}
      end
    else
      %{game | quests: new_quests}
    end
  end

  defp number_of_evil(size) when is_number(size) do
    num_evil =
      case size do
        5 -> 2
        6 -> 2
        7 -> 3
        8 -> 3
        9 -> 3
        10 -> 4
        _ -> if size < 5, do: 1, else: 4
      end

    Kernel.min(size, num_evil)
  end

  def handle_out(game, username) do
    # Mark the active quest
    active_quest_id = Quest.get_active_quest(game.quests).id

    quests =
      game.quests
      |> Enum.map(fn quest ->
        Map.put(quest, :active, quest.id == active_quest_id)
      end)

    requester = Enum.find(game.players, fn player -> player.name == username end)
    players_out = Enum.map(game.players, fn player -> Player.handle_out(player, requester) end)

    quests_out =
      Enum.map(quests, fn quest -> Quest.handle_out(quest, Kernel.length(game.players)) end)

    %{game | players: players_out, quests: quests_out}
  end
end
