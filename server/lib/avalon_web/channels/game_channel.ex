defmodule AvalonWeb.GameChannel do
  use AvalonWeb, :channel

  alias AvalonWeb.Presence
  alias Avalon.Game.Server, as: GameServer
  alias Avalon.Game.Supervisor, as: GameSupervisor

  require Logger

  intercept ["game:state"]

  def join("room:" <> game_name, _params, socket) do
    if String.length(game_name) > 0 do
      case GameServer.game_pid(game_name) do
         pid when is_pid(pid) ->
           send(self(), {:after_join, game_name})

           # Alert the player of the existing game state
           game = GameServer.summary(game_name)
           {:ok, filter_game_state(game, socket), socket}

         nil ->
           send(self(), {:after_join, game_name})
           {:ok, socket}
       end
     else
       logError(socket, "invalid room name")
       {:error, "invalid room name"}
     end
  end


  def handle_info({:after_join, _}, socket) do
    log(socket, "player joined room")

    # Handle the presence state
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} =
      Presence.track(socket, username(socket), %{
        online_at: inspect(System.system_time(:seconds))
      })

    {:noreply, socket}
  end

  def handle_out("game:state", game, socket) do
    push socket, "game:state", filter_game_state(game, socket)
    {:noreply, socket}
  end

  def handle_in("game:start", _payload, socket) do
    "room:" <> game_name = socket.topic
    log(socket, "game started")

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

  defp filter_game_state(game, socket) do
    player =
      Enum.find(game.players, nil, fn player -> player.name == username(socket) end)

    filtered_players =
      Enum.map(game.players, (fn player -> player.name end ))

    if player == nil do
      Map.merge(game, %{players: filtered_players, player: %{name: username(socket), role: :spectator}})
    else
      Map.merge(game, %{players: filtered_players, player: player})
    end
  end

  def handle_in("game:stop", _payload, socket) do
    "room:" <> game_name = socket.topic
    log(socket, "game stopped")

    # If the game is running, stop the game
    if GameServer.game_pid(game_name) != nil do
      GameSupervisor.stop_game(game_name)
    end

    # Alert all players of the new game state
    broadcast!(socket, "game:stop", %{})

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    log(socket, "player left game; reason: #{inspect(reason)}")
    :ok
  end

  defp username(socket) do
    socket.assigns.username
  end

  # Ensures that all logs contain the room and player name
  defp log(socket, message) do
    "room:" <> game_name = socket.topic
    Logger.info("[game: '#{game_name}' | user: '#{username(socket)}'] " <> message)
  end
  defp logError(socket, message) do
    "room:" <> game_name = socket.topic
    Logger.error("[game: '#{game_name}' | user: '#{username(socket)}'] " <> message)
  end
end
