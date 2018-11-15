defmodule AvalonWeb.HomeChannel do
  use AvalonWeb, :channel

  require Logger

  def join("home", _params, socket) do
    Logger.info("New connection to home")
    {:ok, socket}
  end

  def handle_in("room:create", _payload, socket) do
    Logger.info("Creating a new room")
    {:ok, room_pid} = Avalon.Room.Supervisor.start_room()
    room_id = GenServer.call(room_pid, :get_id)
    {:reply, {:ok, %{room_id: room_id}}, socket}
  end
end
