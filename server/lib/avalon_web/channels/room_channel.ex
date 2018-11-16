defmodule AvalonWeb.RoomChannel do
  use AvalonWeb, :channel

  alias AvalonWeb.Presence
  alias Avalon.Room.Server, as: GameServer

  require Logger

  intercept(["room:state"])

  def join("room:" <> room_name, params, socket) do
    new_socket = socket |> assign(:username, params["username"])

    if username(new_socket) == nil || Kernel.byte_size(username(new_socket)) == 0 do
      {:error, "You cannot join a room without a username set."}
    else
      if String.length(room_name) > 0 do
        Logger.info("Player '#{username(new_socket)}' joined room '#{room_name}'")

        find_room(socket, fn _ ->
          send(self(), {:after_join, room_name})
          room = GameServer.summary(room_name)
          {:ok, %{room | game: handle_out_game(room.game, new_socket)}, new_socket}
        end)
      else
        logError(socket, "invalid room name")
        {:error, "invalid room name"}
      end
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

  # GAME ACTIONS

  def handle_in("setting:set", %{"name" => name, "value" => value}, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is changing setting for #{name} to #{value}")
      room = GameServer.set_setting(room_name(socket), name, value)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("game:start", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "game started")
      players = Map.keys(Presence.list(socket))
      new_room = GameServer.start_game(room_name(socket), players)
      broadcast!(socket, "room:state", new_room)
      {:noreply, socket}
    end)
  end

  def handle_in("game:stop", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "game stopped")
      room = GameServer.stop_game(room_name(socket))
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("game:restart", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "restarting game")
      room = GameServer.restart_game(room_name(socket))
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  # PLAYER ACTIONS

  def handle_in("player:ready", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is ready")
      room = GameServer.player_ready(room_name(socket), username(socket))
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("player:assassinate", %{"player" => player}, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is assassinating '#{player}'")
      room = GameServer.assassinate(room_name(socket), username(socket), player)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  # TEAM ACTIONS

  def handle_in("team:select_player", %{"player" => player}, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "selected player '#{player}' for quest")
      room = GameServer.select_quest_member(room_name(socket), username(socket), player)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("team:deselect_player", %{"player" => player}, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "deselected player '#{player}' from quest")
      room = GameServer.deselect_quest_member(room_name(socket), username(socket), player)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("team:begin_voting", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player '#{username(socket)}' began voting")
      room = GameServer.begin_voting(room_name(socket), username(socket))
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("team:accept_vote", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is voing to accept")
      room = GameServer.player_vote(room_name(socket), username(socket), :accept)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("team:reject_vote", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is voing to reject")
      room = GameServer.player_vote(room_name(socket), username(socket), :reject)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  # QUEST ACTIONS

  def handle_in("quest:success", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is playing success quest card")
      room = GameServer.play_quest_card(room_name(socket), username(socket), :success)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  def handle_in("quest:fail", _payload, socket) do
    find_room_with_reply(socket, fn _ ->
      log(socket, "player is playing fail quest card")
      room = GameServer.play_quest_card(room_name(socket), username(socket), :fail)
      broadcast!(socket, "room:state", room)
      {:noreply, socket}
    end)
  end

  # Handle invalid command
  def handle_in(message, payload, socket) do
    logError(socket, "unknown command: '#{message}' payload: '#{inspect(payload)}'")
    {:reply, {:error, "Unknown command"}}
  end

  # Filter our output to only show the player what they are supposed
  # to know.
  def handle_out("room:state", room, socket) do
    push(socket, "room:state", %{
      room
      | game: handle_out_game(room.game, socket)
    })

    {:noreply, socket}
  end

  defp handle_out_game(game, socket) do
    if game == nil do
      nil
    else
      %{
        game
        | players: handle_out_players(game.players, socket),
          quests: handle_out_quests(game.quests, socket)
      }
    end
  end

  defp handle_out_players(players, socket) do
    player_names = Enum.map(players, fn p -> p.name end)

    role =
      if Enum.member?(player_names, username(socket)) do
        Enum.find(players, fn p -> p.name == username(socket) end).role
      else
        Avalon.Role.new(:unknown, :unknown)
      end

    players
    |> Enum.map(fn p ->
      if p.name == username(socket),
        do: p,
        else: %{p | role: Avalon.Role.peek(role, p.role)}
    end)
  end

  defp handle_out_quests(quests, _socket) do
    active_quest =
      Avalon.Quest.get_active_quest(quests) ||
        %Avalon.Quest{id: -1, state: nil, team: nil, num_fails_required: nil, quest_cards: nil}

    quests
    |> Enum.map(fn q ->
      if q.id == active_quest.id,
        do: Map.put(Map.delete(q, :id), :active, true),
        else: Map.put(Map.delete(q, :id), :active, false)
    end)
    |> Enum.map(fn q ->
      quest_card_players =
        q.quest_cards
        |> Enum.map(fn {p, _} -> p end)

      # Show the player the quest card values if the quest is done
      quest_card_values =
        if q |> Avalon.Quest.quest_done_playing?() do
          q.quest_cards
          |> Enum.map(fn {_, c} -> c end)
          |> Enum.shuffle()
        else
          []
        end

      Map.put(q, :quest_card_players, quest_card_players)
      |> Map.put(:quest_cards, quest_card_values)
    end)
  end

  def terminate(reason, socket) do
    log(socket, "player left room; reason: #{inspect(reason)}")
    :ok
  end

  defp username(socket) do
    socket.assigns.username
  end

  defp room_name(socket) do
    "room:" <> room_name = socket.topic
    room_name
  end

  defp find_room(socket, func) do
    room_name = room_name(socket)

    case GameServer.room_pid(room_name) do
      pid when is_pid(pid) ->
        func.(pid)

      nil ->
        {:error, "Room '#{room_name}' does not exist"}
    end
  end

  defp find_room_with_reply(socket, func) do
    room_name = room_name(socket)

    case GameServer.room_pid(room_name) do
      pid when is_pid(pid) ->
        func.(pid)

      nil ->
        {:reply, {:error, "Room '#{room_name}' does not exist"}, socket}
    end
  end

  # Ensures that all logs contain the room and player name
  defp log(socket, message) do
    Logger.info("[room: '#{room_name(socket)}' | user: '#{username(socket)}'] " <> message)
  end

  defp logError(socket, message) do
    Logger.error("[room: '#{room_name(socket)}' | user: '#{username(socket)}'] " <> message)
  end
end
