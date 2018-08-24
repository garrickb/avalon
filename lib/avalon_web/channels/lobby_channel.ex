defmodule Avalon.Web.LobbyChannel do
  use Avalon.Web, :channel

  def join("lobby:lobby", %{"username" => username}, socket) do
    send(self(), {:after_join, username})
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (lobby:lobby).
  def handle_in("shout", %{"msg" => msg}, socket) do
    username = socket.assigns[:username]
    broadcast(socket, "shout", %{msg: msg, username: username})
    {:noreply, socket}
  end

  def handle_info({:after_join, user_name}, socket) do
    #push(socket, "presence_state", Presence.list(socket))
    #{:ok, _ref} = Presence.track(socket, user_name, %{online_at: now()})
    {:noreply, assign(socket, :username, user_name)}
  end
end
