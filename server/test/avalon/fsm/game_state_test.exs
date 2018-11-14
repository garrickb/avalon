defmodule Avalon.FsmGameStateTest do
  use ExUnit.Case

  alias Avalon.FsmGameState, as: State

  test "initial state is waiting" do
    assert State.new().state == :waiting
  end

  # Starting the game

  test "starting the game brings you to quest member selection" do
    game = State.new() |> State.start_game()
    assert game.state == :build_team
  end

  # Selecting quest members

  test "selecting quest members will begin voting" do
    game = State.new() |> State.start_game() |> State.begin_voting()
    assert game.state == :team_vote
  end

  ##########
  # VOTING #
  ##########

  # Rejecting a team

  test "if team is rejected, will go back to team selection" do
    game = State.new() |> State.start_game() |> State.begin_voting() |> State.reject()
    assert game.state == :build_team
  end

  test "rejecting five times in a row results in evil winning" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.reject()

    assert game.state == :game_end_evil
  end

  # Accepting a team

  test "accepted team will begin the quest" do
    game = State.new() |> State.start_game() |> State.begin_voting() |> State.accept()
    assert game.state == :quest
  end

  test "accepting a team will reset the reject counter" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.reject()
      |> State.begin_voting()
      |> State.accept()

    assert game.data.reject_count == 0
    assert game.state == :quest
  end

  ###########
  #  QUEST  #
  ###########

  # Failing a quest

  test "failing a quest will direct to selection state" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()

    assert game.data.failed_count == 1
    assert game.state == :build_team
  end

  test "failing a quest three times will result in an evil win" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()

    assert game.data.failed_count == 3
    assert game.state == :game_end_evil
  end

  test "three fails will result in an evil win even with two successes" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()

    assert game.data.succeeded_count == 2
    assert game.data.failed_count == 3
    assert game.state == :game_end_evil
  end

  test "restart game after an evil win" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.restart()

    assert game.data.succeeded_count == 0
    assert game.data.failed_count == 0
    assert game.data.reject_count == 0
    assert game.state == :waiting
  end

  # Succeeding a quest

  test "succeeding a quest will direct to selection state" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()

    assert game.data.succeeded_count == 1
    assert game.state == :build_team
  end

  test "succeeding a quest three times will result in a good win" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()

    assert game.data.succeeded_count == 3
    assert game.state == :game_end_good
  end

  test "succeeding a quest three times with assassin & merlin will result in waiting for the assassin" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()

    assert game.data.succeeded_count == 3
    assert game.state == :game_end_good_assassin
  end

  test "assassin guesses correctly" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.correct_assassination()

    assert game.state == :game_end_evil
  end

  test "assassin guesses incorrectly" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed_with_assassin_and_merlin()
      |> State.incorrect_assassination()

    assert game.state == :game_end_good
  end

  test "three successes will result in a good win even with two fails" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.fail()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()

    assert game.data.succeeded_count == 3
    assert game.data.failed_count == 2
    assert game.state == :game_end_good
  end

  test "restart game after good win" do
    game =
      State.new()
      |> State.start_game()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.begin_voting()
      |> State.accept()
      |> State.succeed()
      |> State.restart()

    assert game.data.succeeded_count == 0
    assert game.data.failed_count == 0
    assert game.data.reject_count == 0
    assert game.state == :waiting
  end
end
