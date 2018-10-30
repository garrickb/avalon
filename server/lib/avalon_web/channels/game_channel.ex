defmodule AvalonWeb.GameChannel do
  use AvalonWeb, :channel

  alias AvalonWeb.Presence
  alias Avalon.Game.Server, as: GameServer
  alias Avalon.Game.Supervisor, as: GameSupervisor

  require Logger

  def join("room:" <> game_name, _params, socket) do
    Logger.info("Player joined room '#{game_name}'")
    send(self(), {:after_join, game_name})
    {:ok, socket}
  end

  def handle_info({:after_join, game_name}, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, username(socket), %{
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  def handle_in("message", %{"msg" => msg}, socket) do
    broadcast!(socket, "newMessage", %{
      username: username(socket),
      msg: msg
    })

    {:noreply, socket}
  end

  def handle_in("start", _payload, socket) do
    if GameServer.game_pid(game_name) == nil do
      GameSupervisor.start_game(game_name)
      {:noreply, socket}
    end

    {:reply, {:error, "game is already started"}, socket}
  end

  def terminate(reason, socket) do
    Logger.info("Player '#{username(socket)}' has left game, reason: #{inspect(reason)}")
    :ok
  end

  defp username(socket) do
    socket.assigns.username
  end
end
