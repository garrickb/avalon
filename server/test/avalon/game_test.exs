defmodule Avalon.GameTest do
  use ExUnit.Case

  alias Avalon.Game, as: Game

  # Game Constructor Tests

  test "create a game with players" do
    game_name = "game_name"
    players = ["player1", "player2", "player3"]
    game = Game.new(game_name, players)

    assert game.name == game_name
    assert Enum.map(game.players, fn p -> p.name end) == players
  end

  test "a four player game has one evil player" do
    make_and_assert_roles(4, 1)
  end

  test "a five player game has two evil players" do
    make_and_assert_roles(5, 2)
  end

  test "a six player game has two evil players" do
    make_and_assert_roles(6, 2)
  end


  test "a seven player game has three evil players" do
    make_and_assert_roles(7, 3)
  end


  test "an eight player game has three evil players" do
    make_and_assert_roles(8, 3)
  end

  test "a nine player game has three evil players" do
    make_and_assert_roles(9, 3)
  end

  test "a ten player game has four evil players" do
    make_and_assert_roles(10, 4)
  end

  test "an eleven player game has four evil players" do
    make_and_assert_roles(11, 4)
  end

  defp make_and_assert_roles(size, expected_num_evil) do
    expected_num_good = size - expected_num_evil
    game = make_game("name", size)

    assert length(game.players) == size
    assert length(Enum.filter(game.players, fn p -> p.role == :evil end)) == expected_num_evil
    assert length(Enum.filter(game.players, fn p -> p.role == :good end)) == expected_num_good
  end


  defp make_game(size) do
    make_game("game", size)
  end

  defp make_game(name, size) do
    players = Enum.map(1..size, fn num -> "player#{num}" end)
    Game.new(name, players)
  end

  # Waiting State test


  test "player defaults to not ready" do
    player_name = "player1"

    player =
      make_game(1)
        |> get_player(player_name)

    assert player.ready == false
  end

  test "marking a player as ready" do
    player_name = "player1"

    player =
      make_game(1)
        |> Game.set_player_ready(player_name)
        |> get_player(player_name)

    assert player.ready == true
  end

  test "marking a player as ready twice" do
    player_name = "player1"

    player =
      make_game(5)
        |> Game.set_player_ready(player_name)
        |> Game.set_player_ready(player_name)
        |> get_player(player_name)

    assert player.ready == true
  end

  test "marking an invalid player as ready" do
    player_name = "player100"

    make_game(5)
      |> Game.set_player_ready(player_name)
  end

  test "not having all players ready does not advance state" do
    game =
      make_game(5)
        |> Game.set_player_ready("player1")
        |> Game.set_player_ready("player2")
        |> Game.set_player_ready("player3")
        |> Game.set_player_ready("player4")

    assert Game.all_players_ready?(game.players) == false
    assert game.fsm.state == :waiting
  end

  test "marking as players as ready advances the state" do
    game =
      make_game(5)
        |> Game.set_player_ready("player1")
        |> Game.set_player_ready("player2")
        |> Game.set_player_ready("player3")
        |> Game.set_player_ready("player4")
        |> Game.set_player_ready("player5")

        assert Game.all_players_ready?(game.players) == true
    #assert game.fsm.state == :select_quest_members
  end

  defp get_player(game, player_name) do
    Enum.find(game.players, fn p -> p.name == player_name end)
  end
end
