defmodule AvalonWeb.RoomChannel do
  use AvalonWeb, :channel
  alias Phoenix.Socket

  def join("room:" <> room_id, %{"username" => username}, socket) do
    {:ok, room_id, assign_username(socket, username)}
  end

  def handle_in("shout", %{"msg" => msg}, socket) do
    %Socket{
      topic: "room:" <> room_id,
      assigns: %{username: username}
    } = socket

    broadcast socket, "room:#{room_id}:shout", %{msg: msg, username: username}
    {:noreply, socket}
  end

  defp assign_username(socket, username) do
    assign(socket, :username, username)
  end
end
