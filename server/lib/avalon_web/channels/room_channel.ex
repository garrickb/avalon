defmodule AvalonWeb.RoomChannel do
  use AvalonWeb, :channel
  alias Phoenix.Socket

  def join("room:" <> room_id, %{"username" => username}, socket) do
    if valid?(room_id) do
      {:ok, room_id, assign_username(socket, username)}
    else
      {:error, "Invalid room id."}
    end
  end

  def handle_in("message", %{"msg" => msg}, socket) do
    %Socket{
      assigns: %{username: username}
    } = socket

    broadcast socket, "message", %{msg: msg, username: username}
    {:noreply, socket}
  end

  defp valid?(room_id)do
    (String.length room_id) != 0
  end

  defp assign_username(socket, username) do
    assign(socket, :username, username)
  end
end
