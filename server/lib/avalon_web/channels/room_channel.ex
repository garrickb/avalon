defmodule AvalonWeb.RoomChannel do
  use AvalonWeb, :channel
  alias Phoenix.Socket
  alias Avalon.Presence

  def join("room:" <> room_id, %{"username" => username}, socket) do
    send(self(), :after_join)

    if valid?(room_id) do
      {:ok, room_id, assign_username(socket, username)}
    else
      {:error, "Invalid room id"}
    end
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.username, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_in("message", %{"msg" => msg}, socket) do
    %Socket{
      assigns: %{username: username}
    } = socket

    broadcast socket, "newMessage", %{msg: msg, username: username}
    {:noreply, socket}
  end

  defp valid?(room_id)do
    (String.length room_id) != 0
  end

  defp assign_username(socket, username) do
    assign(socket, :username, username)
  end
end
