defmodule Avalon.QuestTest do
  use ExUnit.Case

  alias Avalon.Quest, as: Quest

  # Quest Constructor Tests

  test "creating a quest" do
    quest = new_quest(2, 1)
    assert quest.num_players_required == 2
    assert quest.num_fails_required == 1
    assert quest.outcome == :uncompleted
    assert quest.num_fails == nil
  end

  # Quest Completion Tests

  test "succeed a quest" do
    quest = new_quest(2, 1) |> Quest.complete(0)
    assert quest.outcome == :success
    assert quest.num_fails == 0
  end

  test "fail a quest" do
    quest = new_quest(2, 1) |> Quest.complete(1)
    assert quest.outcome == :failure
    assert quest.num_fails == 1
  end

  test "fail a quest +1" do
    quest = new_quest(2, 1) |> Quest.complete(2)
    assert quest.outcome == :failure
    assert quest.num_fails == 2
  end

  test "fail a quest, but less than required" do
    quest = new_quest(5, 2) |> Quest.complete(1)
    assert quest.outcome == :success
    assert quest.num_fails == 1
  end

  # Adding players to quest

  test "add a player to the quest" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")

    assert quest.selected_players == ["alice"]
  end

  test "add two players to the quest" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")

    assert quest.selected_players == ["alice", "bob"]
  end

  test "adding too many players to the quest will remove the first selected" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.select_player("charlie")

    assert quest.selected_players == ["bob", "charlie"]
  end

  test "adding too many players to the quest twice will remove the first two selected" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.select_player("bob")
      |> Quest.select_player("charlie")
      |> Quest.select_player("daniel")

    assert quest.selected_players == ["charlie", "daniel"]
  end

  test "adding a player from a completed quest will NoOp" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.complete(0)
      |> Quest.select_player("bob")

    assert quest.selected_players == ["alice"]
  end

  # Removing players from quest

  test "remove a player from the quest" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.deselect_player("alice")

    assert quest.selected_players == []
  end

  test "remove an unknown player from a quest will NoOp" do
    quest =
      new_quest(2, 1)
      |> Quest.deselect_player("alice")

    assert quest.selected_players == []
  end

  test "remove an unknown player from a quest that has a player in it will NoOp" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.deselect_player("bob")

    assert quest.selected_players == ["alice"]
  end

  test "removing a player from a completed quest will NoOp" do
    quest =
      new_quest(2, 1)
      |> Quest.select_player("alice")
      |> Quest.complete(0)
      |> Quest.deselect_player("alice")

    assert quest.selected_players == ["alice"]
  end

  # Get All Quests
  test "getting quests for five players will return five quests" do
    assert length(Quest.get_quests(5)) == 5
  end

  test "getting quests for any number of players will return five quests" do
    for n <- 1..15, do: assert(length(Quest.get_quests(n)) == 5)
  end

  # Util

  defp new_quest(num_players_required, num_fails_required) do
    Quest.new(0, num_players_required, num_fails_required)
  end
end
