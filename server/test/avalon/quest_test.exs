defmodule Avalon.QuestTest do
  use ExUnit.Case

  alias Avalon.Quest, as: Quest

  # Quest Constructor Tests

  test "creating a quest" do
    quest = new_quest(2, 1)
    assert quest.state == :uncompleted
    assert quest |> Quest.voting_can_begin?() == false
  end

  # Quest team voting
  test "vote to accept team" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_accept_vote("alice")
      |> Quest.player_accept_vote("bob")

    assert quest |> Quest.team_done_voting?(2) == true
    assert quest |> Quest.team_voting_passed?() == true
  end

  test "vote to reject team" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_reject_vote("alice")
      |> Quest.player_reject_vote("bob")

    assert quest |> Quest.team_done_voting?(2) == true
    assert quest |> Quest.team_voting_passed?() == false
  end

  test "clearing a rejected team adds it to the history" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_reject_vote("alice")
      |> Quest.player_reject_vote("bob")
      |> Quest.team_finished("alice", :reject)

    assert quest |> Quest.team_done_voting?(2) == false
    assert quest.team_history |> length == 1
    assert quest.team_history |> List.first() |> Map.get(:team) |> Avalon.Team.num_votes() == 2
  end

  test "clearing a rejected team twice adds it to the history" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_reject_vote("alice")
      |> Quest.player_reject_vote("bob")
      |> Quest.team_finished("alice", :reject)
      |> Quest.player_accept_vote("alice")
      |> Quest.player_reject_vote("bob")
      |> Quest.team_finished("bob", :reject)

    assert quest |> Quest.team_done_voting?(2) == false
    assert quest.team_history |> length == 2
    last_team = quest.team_history |> List.first() |> Map.get(:team)
    assert quest.team_history |> List.first() |> Map.get(:king) == "bob"
    assert last_team |> Avalon.Team.num_votes() == 2
    assert last_team |> Avalon.Team.num_votes(:accept) == 1
  end

  # Quest Completion Tests

  test "select members for a quest" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")

    assert quest.state == :uncompleted
    assert quest |> Quest.voting_can_begin?() == true
  end

  test "player that is not on quest cannot play a quest card" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :fail)
      |> Quest.player_quest_card("charlie", :success)

    assert quest.state == :uncompleted
  end

  test "player cannot play two quest cards" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :success)
      |> Quest.player_quest_card("alice", :success)

    assert quest.state == :uncompleted
  end

  test "fail a quest with one fail card" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :fail)
      |> Quest.player_quest_card("bob", :success)

    assert quest.state == :failure
  end

  test "fail a quest over required amount" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :fail)
      |> Quest.player_quest_card("bob", :fail)

    assert quest.state == :failure
  end

  test "succeed a quest" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :success)
      |> Quest.player_quest_card("bob", :success)

    assert quest.state == :success
  end

  test "succeed a quest with a failure card played" do
    quest =
      new_quest(2, 2)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.player_quest_card("alice", :fail)
      |> Quest.player_quest_card("bob", :success)

    assert quest.state == :success
  end

  # Util

  defp new_quest(num_players_required, num_fails_required) do
    Quest.new(0, num_players_required, num_fails_required)
  end
end
