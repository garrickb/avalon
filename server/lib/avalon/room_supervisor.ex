defmodule Avalon.Room.Supervisor do
  @moduledoc """
  A supervisor that starts `Server` processes dynamically.
  """

  use DynamicSupervisor
  require Logger
  alias Avalon.Room.Server, as: RoomServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a `Server` process and supervises it.
  """
  def start_room() do
    Logger.info("Starting new room")

    child_spec = %{
      id: RoomServer,
      start: {RoomServer, :start_link, []},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminates the `Server` process normally. It won't be restarted.
  """
  def stop_game(room_name) do
    Logger.info("Stopping room: '#{room_name}'")

    :ets.delete(:rooms_table, room_name)

    child_pid = RoomServer.room_pid(room_name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
