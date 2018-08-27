defmodule AvalonWeb.RoomChannelTest do
  use AvalonWeb.ChannelCase

  alias AvalonWeb.RoomChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{})
      |> subscribe_and_join(RoomChannel, "room:room_id", %{"username" => "Garrick"})

    {:ok, socket: socket}
  end

  test "message broadcasts to room:room_id", %{socket: socket} do
    push socket, "message", %{"msg" => "hello world"}
    assert_broadcast "message", %{:msg => "hello world", :username => "Garrick"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{:msg => "hello world"}
    assert_push "broadcast", %{:msg => "hello world"}
  end
end
