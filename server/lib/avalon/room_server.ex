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

  def summary(room_name) do
    GenServer.call(via_tuple(room_name), :summary)
  end

  def start_game(room_name, players) do
    GenServer.call(via_tuple(room_name), {:start_game, players})
  end

  def stop_game(room_name) do
    GenServer.call(via_tuple(room_name), :stop_game)
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

  def handle_call(:id, _from, room) do
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
