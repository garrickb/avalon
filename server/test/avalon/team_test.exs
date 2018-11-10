defmodule Avalon.TeamTest do
  use ExUnit.Case

  alias Avalon.Team, as: Team

  # Adding players

  test "add a player to the quest" do
    team =
      Team.new(1)
      |> Team.add_player("alice")

    assert team.players == ["alice"]
  end

  test "add two players to the quest" do
    team =
      Team.new(2)
      |> Team.add_player("alice")
      |> Team.add_player("bob")

    assert team.players == ["alice", "bob"]
  end

  test "adding too many players to the quest will remove the first selected" do
    team =
      Team.new(2)
      |> Team.add_player("alice")
      |> Team.add_player("bob")
      |> Team.add_player("charlie")

    assert team.players == ["bob", "charlie"]
  end

  test "adding too many players to the quest twice will remove the first two selected" do
    team =
      Team.new(2)
      |> Team.add_player("alice")
      |> Team.add_player("bob")
      |> Team.add_player("charlie")
      |> Team.add_player("daniel")

    assert team.players == ["charlie", "daniel"]
  end

  test "checking if a player is on team" do
    team =
      Team.new(1)
      |> Team.add_player("alice")

    assert team |> Team.on_team?("alice") == true
    assert team |> Team.on_team?("bob") == false
  end

  test "team does not have number players required" do
    team = Team.new(1)

    assert team |> Team.has_num_players_required?() == false
  end

  test "team has the correct number players required" do
    team =
      Team.new(1)
      |> Team.add_player("alice")

    assert team |> Team.has_num_players_required?() == true
  end

  # Removing players
  test "removing a player from quest" do
    team =
      Team.new(1)
      |> Team.add_player("alice")
      |> Team.remove_player("alice")

    assert team.players == []
  end

  test "removing a player from quest that doesn't exist" do
    team =
      Team.new(1)
      |> Team.remove_player("alice")

    assert team.players == []
  end

  # Voting
  test "cannot vote on an incomplete team" do
    team =
      Team.new(2)
      |> Team.add_player("alice")
      |> Team.player_vote("alice", :accept)

    assert team |> Team.has_num_players_required?() == false
    assert team |> Team.num_votes() == 0
    assert team |> Team.num_votes(:accept) == 0
  end

  test "vote on a full team" do
    team =
      Team.new(1)
      |> Team.add_player("alice")
      |> Team.player_vote("alice", :accept)

    assert team |> Team.has_num_players_required?() == true
    assert team |> Team.num_votes() == 1
    assert team |> Team.num_votes(:accept) == 1
  end
end
