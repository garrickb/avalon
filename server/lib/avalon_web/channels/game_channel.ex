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
         Logger.info("Summary: #{inspect(summary)}")
         {:ok, summary, socket}

       nil ->
         send(self(), {:after_join, game_name})
         {:ok, socket}
     end
  end

  def handle_info({:after_join, game_name}, socket) do
    Logger.info("Player '#{username(socket)}' joined room '#{game_name}'")

    push(socket, "msg:new", %{username: nil, msg: "Welcome to #{game_name}!"})
    broadcast!(socket, "user:joined", %{user: username(socket)})

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
      Logger.info("Game Create; Presence list: #{inspect(Map.keys(Presence.list(socket)))}")

      players = Map.keys(Presence.list(socket))
      GameSupervisor.start_game(game_name, players)

      # Alert all players of the new game
      summary = GameServer.summary(game_name)

      Logger.info("Broadcasting game:state : #{inspect(summary)}")
      broadcast!(socket, "game:state", summary)
    end

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    Logger.info("Player '#{username(socket)}' has left game, reason: #{inspect(reason)}")
    :ok
  end

  defp username(socket) do
    socket.assigns.username
  end
end
