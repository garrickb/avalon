defmodule Avalon.PlayerTest do
  use ExUnit.Case

  alias Avalon.Player, as: Player

  # Player Constructor Tests

  test "creating a player" do
    name = "bob"
    role = :good

    player = Player.new(name, role)
    assertPlayer(player, name, role, false, false)
  end

  test "creating players from a list" do
    names = ["alice", "bob", "charlie", "daniel"]
    roles = [:alice_role, :bob_role, :charlie_role, :daniel_role]

    players = Player.newFromList(names, roles)
    for n <- 0..3, do: assertPlayer(Enum.at(players, n), Enum.at(names, n), Enum.at(roles, n), false, false)
  end

  # Player Ready

  test "mark a player as ready" do
    name = "bob"
    role = :good

    player = Player.new(name, role) |> Player.ready
    assertPlayer(player, name, role, true, false)
  end


  test "mark a player as ready twice" do
    name = "bob"
    role = :good

    player = Player.new(name, role) |> Player.ready |> Player.ready
    assertPlayer(player, name, role, true, false)
  end

  # Utils

  defp assertPlayer(player, expectedName, expectedRole, expectedReady, expectedKing) do
    assert player.name == expectedName
    assert player.role == expectedRole
    assert player.ready == expectedReady
    assert player.king == expectedKing
  end
end
