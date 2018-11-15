defmodule Avalon.Room.Server do
  @moduledoc """
  A room server process that holds a `Lobby` struct as its state.
  """

  use GenServer

  require Logger

  @timeout :timer.minutes(30)

  # Client Interface

  @doc """
  Spawns a new room server process under a randomly generated name
  """
  def start_link() do
    room_name = generate_id(4)
    name = via_tuple(room_name)
    GenServer.start_link(__MODULE__, {room_name}, name: name)
  end

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789" |> String.split("", trim: true)
  defp generate_id(length) do
    Enum.reduce(1..length, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end

  # LOBBY CLIENT

  def summary(room_name) do
    GenServer.call(via_tuple(room_name), :summary)
  end

  def start_game(room_name, players) do
    GenServer.call(via_tuple(room_name), {:start_game, players})
  end

  def stop_game(room_name) do
    GenServer.call(via_tuple(room_name), :stop_game)
  end

  def set_setting(room_name, setting_name, setting_value) do
    GenServer.call(via_tuple(room_name), {:set_setting, setting_name, setting_value})
  end

  # GAME CLIENT

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

  def assassinate(game_name, requester, player) do
    GenServer.call(via_tuple(game_name), {:assassinate, requester, player})
  end

  def restart_game(game_name) do
    GenServer.call(via_tuple(game_name), {:restart_game})
  end

  @doc """
  Returns a tuple used to register and lookup a room server process by name.
  """
  def via_tuple(room_name) do
    {:via, Registry, {Avalon.Room.Registry, room_name}}
  end

  @doc """
  Returns the `pid` of the room server process registered under the
  given `room_name`, or `nil` if no process is registered.
  """
  def room_pid(room_name) do
    room_name
    |> via_tuple()
    |> GenServer.whereis()
  end

  # Server Callbacks

  def init({room_name}) do
    room =
      case :ets.lookup(:rooms_table, room_name) do
        [] ->
          room = Avalon.Room.new(room_name)
          :ets.insert(:rooms_table, {room_name, room})
          room

        [{^room_name, room}] ->
          room
      end

    Logger.info("Initializing room server '#{room_name}'.")

    {:ok, room, @timeout}
  end

  # LOBBY LOGIC

  def handle_call(:get_id, _from, room) do
    {:reply, room.id, room, @timeout}
  end

  def handle_call(:summary, _from, room) do
    {:reply, room, room, @timeout}
  end

  def handle_call({:start_game, players}, _from, room) do
    new_room = Avalon.Room.start_game(room, players)
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  def handle_call(:stop_game, _from, room) do
    new_room = Avalon.Room.stop_game(room)
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:set_setting, name, value}, _from, room) do
    new_room = Avalon.Room.set_setting(room, name, value)
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  # GAME LOGIC

  def handle_call({:player_ready, requester}, _from, room) do
    new_game = Avalon.Game.set_player_ready(room.game, requester)
    new_room = %{room | game: new_game}
    :ets.insert(:rooms_table, {my_room_name(), %{room | game: new_room}})
    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:select_quest_member, requester, player}, _from, room) do
    if room.game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.select_player(room.game, player)
      new_room = %{room | game: new_game}
      :ets.insert(:rooms_table, {my_room_name(), new_room})
      {:reply, new_room, new_room, @timeout}
    else
      Logger.warn(
        "Requester '#{requester} cannot select player '#{player}' because they are not the king"
      )

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:deselect_quest_member, requester, player}, _from, room) do
    if room.game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.deselect_player(room.game, player)
      new_room = %{room | game: new_game}
      :ets.insert(:rooms_table, {my_room_name(), new_room})
      {:reply, new_room, new_room, @timeout}
    else
      Logger.warn(
        "Requester '#{requester} cannot deselect player '#{player}' because they are not the king"
      )

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:begin_voting, requester}, _from, room) do
    if room.game.players |> Avalon.Player.is_king?(requester) do
      new_game = Avalon.Game.begin_voting(room.game)
      new_room = %{room | game: new_game}
      :ets.insert(:rooms_table, {my_room_name(), new_room})
      {:reply, new_room, new_room, @timeout}
    else
      Logger.warn("Requester '#{requester} cannot begin voting because they are not the king")
      {:reply, nil, @timeout}
    end
  end

  def handle_call({:player_vote, requester, vote}, _from, game) do
    new_room = Avalon.Game.vote(game, requester, vote)

    :ets.insert(:rooms_table, {my_room_name(), new_room})

    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:reject_vote, player}, _from, game) do
    new_room = Avalon.Game.vote(game, player, :reject)

    :ets.insert(:rooms_table, {my_room_name(), new_room})

    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:accept_vote, player}, _from, room) do
    new_game = Avalon.Game.vote(room.game, player, :accept)
    new_room = %{room | game: new_game}
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:play_quest_card, player, card}, _from, room) do
    new_game = Avalon.Game.quest_play_card(room.game, player, card)
    new_room = %{room | game: new_game}
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  def handle_call({:assassinate, requester, player}, _from, room) do
    if room.game.players |> Avalon.Player.is_assassin?(requester) do
      new_game = Avalon.Game.assassinate_player(room.game, player)
      new_room = %{room | game: new_game}
      :ets.insert(:rooms_table, {my_room_name(), new_room})
      {:reply, new_room, new_room, @timeout}
    else
      Logger.warn(
        "Requester '#{requester} cannot assassinate player '#{player}' because they are not the assassin"
      )

      {:reply, nil, @timeout}
    end
  end

  def handle_call({:restart_game}, _from, room) do
    player_names = room.game.players |> Enum.map(fn p -> p.name end)
    new_game = Avalon.Game.new(player_names, room.settings)
    new_room = %{room | game: new_game}
    :ets.insert(:rooms_table, {my_room_name(), new_room})
    {:reply, new_room, new_room, @timeout}
  end

  # SERVER LOIC

  def handle_info(:timeout, room) do
    room_name = my_room_name()

    Logger.info("room '#{room_name}' has timed out")
    {:stop, {:shutdown, :timeout}, room}
  end

  def terminate({:shutdown, :timeout}, _room) do
    room_name = my_room_name()

    Logger.info("Terminating room server process '#{room_name}'")
    :ets.delete(:rooms_table, room_name)
    :ok
  end

  def terminate(_reason, _room) do
    room_name = my_room_name()

    Logger.info("room '#{room_name}' terminated")
    :ok
  end

  defp my_room_name do
    Registry.keys(Avalon.Room.Registry, self()) |> List.first()
  end
end
