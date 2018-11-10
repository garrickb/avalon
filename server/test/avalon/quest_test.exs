defmodule Avalon.QuestTest do
  use ExUnit.Case

  alias Avalon.Quest, as: Quest

  # Quest Constructor Tests

  test "creating a quest" do
    quest = new_quest(2, 1)
    assert quest.state == :uncompleted
    assert quest |> Quest.voting_can_begin?() == false
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
