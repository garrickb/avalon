defmodule AvalonWeb.GameChannel do
  use AvalonWeb, :channel

  alias AvalonWeb.Presence
  alias Avalon.Game.Server, as: GameServer
  alias Avalon.Game.Supervisor, as: GameSupervisor

  require Logger

  intercept(["game:state"])

  def join("room:" <> game_name, _params, socket) do
    if String.length(game_name) > 0 do
      case GameServer.game_pid(game_name) do
        pid when is_pid(pid) ->
          send(self(), {:after_join, game_name})

          # Alert the player of the existing game state
          game = GameServer.summary(game_name)
          {:ok, handle_out_game(game, socket), socket}

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

  def handle_in("player:ready", _payload, socket) do
    "room:" <> game_name = socket.topic

    case GameServer.game_pid(game_name) do
      pid when is_pid(pid) ->
        game = GameServer.player_ready(game_name, username(socket))

        log(socket, "player is ready")
        broadcast!(socket, "game:state", game)

        {:noreply, socket}

      nil ->
        logError(socket, "attempted to ready a player in non-existent game")
        {:reply, {:error, %{reason: "Game does not exist"}}, socket}
    end
  end

  def handle_in("player:select_quest_member", %{"player" => player}, socket) do
    "room:" <> game_name = socket.topic

    case GameServer.game_pid(game_name) do
      pid when is_pid(pid) ->
        game = GameServer.select_quest_member(game_name, username(socket), player)

        if game != nil do
          log(socket, "selected player #{player}")
          broadcast!(socket, "game:state", game)
          {:noreply, socket}
        else
          {:reply, {:error, %{reason: "Error selecting quest member."}}, socket}
        end

      nil ->
        logError(socket, "attempted to select a player for a quest in non-existent game")
        {:reply, {:error, %{reason: "Game does not exist"}}, socket}
    end
  end

  def handle_in("player:deselect_quest_member", %{"player" => player}, socket) do
    "room:" <> game_name = socket.topic

    case GameServer.game_pid(game_name) do
      pid when is_pid(pid) ->
        game = GameServer.deselect_quest_member(game_name, username(socket), player)

        if game != nil do
          log(socket, "deselected player #{player}")
          broadcast!(socket, "game:state", game)
          {:noreply, socket}
        else
          {:reply, {:error, %{reason: "Error deselecting quest member."}}, socket}
        end

      nil ->
        logError(socket, "attempted to deselect a player for a quest in non-existent game")
        {:reply, {:error, %{reason: "Game does not exist"}}, socket}
    end
  end

  def handle_in(message, payload, socket) do
    logError(socket, "unknown command: '#{message}' payload: '#{inspect(payload)}'")
    {:noreply, socket}
  end

  def handle_out("game:state", game, socket) do
    push(socket, "game:state", handle_out_game(game, socket))

    {:noreply, socket}
  end

  defp handle_out_game(game, socket) do
    %{
      game
      | players: handle_out_players(game.players, socket),
        quests: handle_out_quests(game.quests, socket)
    }
  end

  defp handle_out_players(players, socket) do
    players
    |> Enum.map(fn p ->
      if p.name == username(socket),
        do: p,
        else: %{p | role: :unknown}
    end)
  end

  defp handle_out_quests(quests, _socket) do
    active_quest = Avalon.Quest.get_active_quest(quests)

    quests
    |> Enum.map(fn q ->
      if q.id == active_quest.id,
        do: Map.put(Map.delete(q, :id), :active, true),
        else: Map.put(Map.delete(q, :id), :active, false)
    end)
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
