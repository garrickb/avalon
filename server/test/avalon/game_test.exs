defmodule Avalon.GameTest do
  use ExUnit.Case

  alias Avalon.Game, as: Game
  alias Avalon.Player, as: Player

  # Game Constructor Tests

  test "create a game with players" do
    players = ["player1", "player2", "player3"]
    game = Game.new(players, Avalon.Settings.new())

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
    game = make_game(size)

    assert length(game.players) == size

    assert length(Enum.filter(game.players, fn p -> p.role.alignment == :evil end)) ==
             expected_num_evil

    assert length(Enum.filter(game.players, fn p -> p.role.alignment == :good end)) ==
             expected_num_good
  end

  defp make_game(size) do
    players = Enum.map(1..size, fn num -> "player#{num}" end)
    Game.new(players, Avalon.Settings.new())
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
    assert game.fsm.state == :build_team
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
    assert game.fsm.state == :build_team
  end

  test "cannot begin voting if not enough players are selected" do
    game =
      make_game(5)
      |> all_players_ready()
      |> Game.select_player("player1")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :build_team
  end

  test "can begin voting if players are selected" do
    game =
      make_game(5)
      |> all_players_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player2")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :team_vote
  end

  test "cannot begin voting after selecting same player twice" do
    game =
      make_game(5)
      |> all_players_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player1")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :build_team
  end

  test "can begin voting after selecting too many players" do
    game =
      make_game(5)
      |> all_players_ready()
      |> Game.select_player("player1")
      |> Game.select_player("player2")
      |> Game.select_player("player3")
      |> Game.select_player("player4")
      |> Game.select_player("player5")
      |> Game.begin_voting()

    assert Player.all_players_ready?(game.players) == true
    assert game.fsm.state == :team_vote
  end

  test "can vote to accept" do
    game =
      make_game(5)
      |> all_players_ready()
      |> select_players_and_begin_voting()
      |> all_players_vote(:accept)

    assert game.fsm.state == :quest
  end

  test "can vote to reject" do
    game =
      make_game(5)
      |> all_players_ready()
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)

    assert game.fsm.state == :build_team
  end

  test "voting to reject will select a new king" do
    game = make_game(5)

    game_after_reject =
      all_players_ready(game)
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)

    king_before_reject = Player.get_king(game.players)
    king_after_reject = Player.get_king(game_after_reject.players)

    assert king_before_reject.name != king_after_reject.name
  end

  test "voting to accept will not a new king" do
    game = make_game(5)

    game_after_reject =
      all_players_ready(game)
      |> select_players_and_begin_voting()
      |> all_players_vote(:accept)

    king_before_reject = Player.get_king(game.players)
    king_after_reject = Player.get_king(game_after_reject.players)

    assert king_before_reject.name == king_after_reject.name
  end

  test "can vote to reject twice" do
    game =
      make_game(5)
      |> all_players_ready()
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)

    assert game.fsm.state == :build_team
  end

  test "evil win after failing five times" do
    game =
      make_game(5)
      |> all_players_ready()
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)
      |> select_players_and_begin_voting()
      |> all_players_vote(:reject)

    assert game.fsm.state == :game_end_evil
  end

  defp all_players_ready(game) do
    assert game.fsm.state == :waiting

    player_names = Enum.map(game.players, fn p -> p.name end)

    Enum.reduce(player_names, game, fn player, acc -> Game.set_player_ready(acc, player) end)
    |> Game.begin_voting()
  end

  defp select_players_and_begin_voting(game) do
    assert game.fsm.state == :build_team
    player_names = Enum.map(game.players, fn p -> p.name end)

    Enum.reduce(player_names, game, fn player, acc -> Game.select_player(acc, player) end)
    |> Game.begin_voting()
  end

  defp all_players_vote(game, vote) when is_atom(vote) do
    assert game.fsm.state == :team_vote
    player_names = Enum.map(game.players, fn p -> p.name end)
    Enum.reduce(player_names, game, fn player, acc -> Game.vote(acc, player, vote) end)
  end

  defp get_player(game, player_name) do
    Enum.find(game.players, fn p -> p.name == player_name end)
  end
end
