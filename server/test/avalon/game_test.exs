defmodule Avalon.GameTest do
  use ExUnit.Case

  alias Avalon.Game, as: Game
  alias Avalon.Player, as: Player

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

  test "not having all players ready" do
    game =
      make_game(5)
      |> Game.set_player_ready("player1")
      |> Game.set_player_ready("player2")
      |> Game.set_player_ready("player3")
      |> Game.set_player_ready("player4")

    assert Player.all_players_ready?(game.players) == false
    assert game.fsm.state == :waiting
  end

  test "marking as players as ready" do
    game =
      make_game(5)
      |> Game.set_player_ready("player1")
      |> Game.set_player_ready("player2")
      |> Game.set_player_ready("player3")
      |> Game.set_player_ready("player4")
      |> Game.set_player_ready("player5")

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :select_quest_members
  end

  test "cannot begin voting without having players selected" do
    game =
      make_game(5)
      |> Game.set_player_ready("player1")
      |> Game.set_player_ready("player2")
      |> Game.set_player_ready("player3")
      |> Game.set_player_ready("player4")
      |> Game.set_player_ready("player5")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :select_quest_members
  end

  test "cannot begin voting if not enough players are selected" do
    game =
      make_game(5)
      |> all_ready()
      |> Game.select_player("player1")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :select_quest_members
  end

  test "can begin voting if players are selected" do
    game =
      make_game(5)
      |> all_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player2")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :vote_on_members
  end

  test "cannot begin voting after selecting same player twice" do
    game =
      make_game(5)
      |> all_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player1")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :select_quest_members
  end

  test "can begin voting after selecting too many players" do
    game =
      make_game(5)
      |> all_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player2")
      |> Game.select_player("player3")
      |> Game.select_player("player4")
      |> Game.select_player("player5")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :vote_on_members
  end

  test "can vote to accept" do
    game =
      make_game(5)
      |> all_ready()
      |> select_players_and_begin_voting()
      |> Game.vote(:accept, "player1")
      |> Game.vote(:accept, "player2")
      |> Game.vote(:accept, "player3")
      |> Game.vote(:accept, "player4")
      |> Game.vote(:accept, "player5")

    assert game.fsm.state == :go_on_quest
  end

  test "can vote to reject" do
    game =
      make_game(5)
      |> all_ready()
      |> select_players_and_begin_voting()
      |> Game.vote(:reject, "player1")
      |> Game.vote(:reject, "player2")
      |> Game.vote(:reject, "player3")
      |> Game.vote(:reject, "player4")
      |> Game.vote(:reject, "player5")

    assert game.fsm.state == :select_quest_members
  end

  test "can vote to reject twice" do
    game =
      make_game(5)
      |> all_ready()
      |> select_players_and_begin_voting()
      |> all_vote(:reject)

    assert game.fsm.state == :select_quest_members
  end

  test "evil win after failing five times" do
    game =
      make_game(5)
      |> all_ready()
      |> select_players_and_begin_voting()
      |> all_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_vote(:reject)

    assert game.fsm.state == :evil_wins
  end

  defp all_ready(game) do
    assert game.fsm.state == :waiting

    player_names = Enum.map(game.players, fn p -> p.name end)

    Enum.reduce(player_names, game, fn player, acc -> Game.set_player_ready(acc, player) end)
    |> Game.begin_voting()
  end

  defp select_players_and_begin_voting(game) do
    assert game.fsm.state == :select_quest_members
    player_names = Enum.map(game.players, fn p -> p.name end)

    Enum.reduce(player_names, game, fn player, acc -> Game.select_player(acc, player) end)
    |> Game.begin_voting()
  end

  defp all_vote(game, vote) when is_atom(vote) do
    assert game.fsm.state == :vote_on_members
    player_names = Enum.map(game.players, fn p -> p.name end)
    Enum.reduce(player_names, game, fn player, acc -> Game.vote(acc, vote, player) end)
  end

  defp get_player(game, player_name) do
    Enum.find(game.players, fn p -> p.name == player_name end)
  end
end
