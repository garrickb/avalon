defmodule Avalon.Game.Server do
  @moduledoc """
  A game server process that holds a `Game` struct as its state.
  """

  use GenServer

  alias Avalon.Settings, as: Settings

  require Logger

  @timeout :timer.hours(1)

  # Client Interface

  @doc """
  Spawns a new game server process registered under the given `game_name`.
  """
  def start_link(game_name, players) do
    name = via_tuple(game_name)
    GenServer.start_link(__MODULE__, {game_name, players}, name: name)
  end

  def summary(game_name) do
    GenServer.call(via_tuple(game_name), :summary)
  end

  def player_ready(game_name, requester) do
    GenServer.call(via_tuple(game_name), {:player_ready, requester})
  end

  def select_quest_member(game_name, requester, player) do
    GenServer.call(via_tuple(game_name), {:select_quest_member, requester, player})
  end

  def deselect_quest_member(game_name, requester, player) do
    GenServer.call(via_tuple(game_name), {:deselect_quest_member, requester, player})
  end

  def begin_voting(game_name, requester) do
    GenServer.call(via_tuple(game_name), {:begin_voting, requester})
  end

  def player_vote(game_name, requester, vote) do
    GenServer.call(via_tuple(game_name), {:player_vote, requester, vote})
  end

  def play_quest_card(game_name, requester, card) do
    GenServer.call(via_tuple(game_name), {:play_quest_card, requester, card})
  end

  @doc """
  Returns a tuple used to register and lookup a game server process by name.
  """
  def via_tuple(game_name) do
    {:via, Registry, {Avalon.GameRegistry, game_name}}
  end

  @doc """
  Returns the `pid` of the game server process registered under the
  given `game_name`, or `nil` if no process is registered.
  """
  def game_pid(game_name) do
    game_name
    |> via_tuple()
    |> GenServer.whereis()
  end

  # Server Callbacks

  def init({game_name, players}) do
    game =
      case :ets.lookup(:games_table, game_name) do
        [] ->
          game = Avalon.Game.new(game_name, players, Settings.new())
          :ets.insert(:games_table, {game_name, game})
          game

        [{^game_name, game}] ->
          game
      end

    Logger.info("Initializing game server '#{game_name}'.")

    {:ok, game, @timeout}
  end

  def handle_call(:summary, _from, game) do
    {:reply, game, game, @timeout}
  end

  def handle_call({:player_ready, requester}, _from, game) do
    new_game = Avalon.Game.set_player_ready(game, requester)

    :ets.insert(:games_table, {my_game_name(), new_game})

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:select_quest_member, requester, player}, _from, game) do
    if game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.select_player(game, player)

      :ets.insert(:games_table, {my_game_name(), new_game})

      {:reply, new_game, new_game, @timeout}
    else
      Logger.warn(
        "Requester '#{requester} cannot select player '#{player}' because they are not the king"
      )

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:deselect_quest_member, requester, player}, _from, game) do
    if game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.deselect_player(game, player)

      :ets.insert(:games_table, {my_game_name(), new_game})

      {:reply, new_game, new_game, @timeout}
    else
      Logger.warn(
        "Requester '#{requester} cannot deselect player '#{player}' because they are not the king"
      )

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:begin_voting, requester}, _from, game) do
    if game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.begin_voting(game)

      :ets.insert(:games_table, {my_game_name(), new_game})

      {:reply, new_game, new_game, @timeout}
    else
      Logger.warn("Requester '#{requester} cannot begin voting because they are not the king")

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:player_vote, requester, vote}, _from, game) do
    new_game = Avalon.Game.vote(game, requester, vote)

    :ets.insert(:games_table, {my_game_name(), new_game})

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:reject_vote, player}, _from, game) do
    new_game = Avalon.Game.vote(game, player, :reject)

    :ets.insert(:games_table, {my_game_name(), new_game})

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:accept_vote, player}, _from, game) do
    new_game = Avalon.Game.vote(game, player, :accept)

    :ets.insert(:games_table, {my_game_name(), new_game})

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:play_quest_card, player, card}, _from, game) do
    new_game = Avalon.Game.quest_play_card(game, player, card)

    :ets.insert(:games_table, {my_game_name(), new_game})

    {:reply, new_game, new_game, @timeout}
  end

  def handle_info(:timeout, game) do
    game_name = my_game_name()

    Logger.info("Game '#{game_name}' has timed out")
    {:stop, {:shutdown, :timeout}, game}
  end

  def terminate({:shutdown, :timeout}, _game) do
    game_name = my_game_name()

    Logger.info("Terminating game server process '#{game_name}'")
    :ets.delete(:games_table, game_name)
    :ok
  end

  def terminate(_reason, _game) do
    game_name = my_game_name()

    Logger.info("Game '#{game_name}' terminated")
    :ok
  end

  defp my_game_name do
    Registry.keys(Avalon.GameRegistry, self()) |> List.first()
  end
end
