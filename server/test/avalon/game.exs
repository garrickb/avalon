defmodule Avalon.GameTest do
  use ExUnit.Case

  alias Avalon.Game, as: Game

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

  defp make_game(name, size) do
    players = Enum.map(1..size, fn num -> "player#{num}" end)
    Game.new(name, players)
  end
end
