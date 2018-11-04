defmodule AvalonWeb.GameChannel do
  use AvalonWeb, :channel

  alias AvalonWeb.Presence
  alias Avalon.Game.Server, as: GameServer
  alias Avalon.Game.Supervisor, as: GameSupervisor

  require Logger

  def join("room:" <> game_name, _params, socket) do
    case GameServer.game_pid(game_name) do
       pid when is_pid(pid) ->
         send(self(), {:after_join, game_name})
         summary = GameServer.summary(game_name)
         {:ok, summary, socket}

       nil ->
         send(self(), {:after_join, game_name})
         {:ok, socket}
     end
  end

  def handle_info({:after_join, game_name}, socket) do
    Logger.info("Player '#{username(socket)}' joined room '#{game_name}'")
    broadcast_from!(socket, "msg:new", %{username: nil, msg: "'#{username(socket)}' joined the game"})
    push(socket, "msg:new", %{username: nil, msg: "Welcome to #{game_name}!"})

    # Handle the presence state
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} =
      Presence.track(socket, username(socket), %{
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  def handle_in("message", %{"msg" => msg}, socket) do
    broadcast!(socket, "msg:new", %{
      username: username(socket),
      msg: msg
    })

    {:noreply, socket}
  end

  def handle_in("game:start", _payload, socket) do
    "room:" <> game_name = socket.topic

    # If the game is not already started, start the game
    if GameServer.game_pid(game_name) == nil do
      players = Map.keys(Presence.list(socket))
      GameSupervisor.start_game(game_name, players)

      # Alert all players of the new game state
      summary = GameServer.summary(game_name)
      broadcast!(socket, "game:state", summary)
    end

    {:noreply, socket}
  end

  def handle_in("game:stop", _payload, socket) do
    "room:" <> game_name = socket.topic

    # If the game is running, stop the game
    if GameServer.game_pid(game_name) != nil do
      GameSupervisor.stop_game(game_name)
    end

    # Alert all players of the new game state
    broadcast!(socket, "game:stop", %{})

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.info("Player '#{username(socket)}' has left game, reason: #{inspect(reason)}")
    broadcast!(socket, "msg:new", %{username: nil, msg: "'#{username(socket)}' has left game"})
    :ok
  end

  defp username(socket) do
    socket.assigns.username
  end
end
