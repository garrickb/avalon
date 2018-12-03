defmodule Avalon.Team do
  @enforce_keys [:players, :num_players_required, :votes]
  defstruct [:players, :num_players_required, :votes]

  alias Avalon.Team

  require Logger

  @doc """
  Creates an empty team.
  """
  def new(num_players_required) do
    %Team{players: [], num_players_required: num_players_required, votes: %{}}
  end

  @doc """
  Add a player to the team, making sure not to go over the required number of players.
  """
  def add_player(team, player_name) when is_binary(player_name) do
    if team |> on_team?(player_name) do
      team
    else
      # Don't go over the number of required players. FIFO.
      new_players =
        if length(team.players) + 1 > team.num_players_required do
          [_ | players] = team.players
          players ++ [player_name]
        else
          team.players ++ [player_name]
        end

      %{team | players: new_players}
    end
  end

  @doc """
  Remove a player from the team.
  """
  def remove_player(team, player_name) when is_binary(player_name) do
    if team |> on_team?(player_name) do
      new_players = team.players |> Enum.filter(fn n -> n != player_name end)
      %{team | players: new_players}
    else
      team
    end
  end

  @doc """
  Returns whether or not a given player is on the team
  """
  def on_team?(team, player_name) when is_binary(player_name) do
    team.players |> Enum.member?(player_name)
  end

  @doc """
  Returns whether or not the team has the required number of players.
  """
  def has_num_players_required?(team) do
    length(team.players) == team.num_players_required
  end

  @doc """
  Stores a player's vote on the team.
  """
  def player_vote(team, player_name, vote) when is_atom(vote) do
    if team |> has_num_players_required?() do
      new_votes = Map.put(team.votes, player_name, vote)
      %{team | votes: new_votes}
    else
      Logger.warn("Cannot vote on a team that is missing players")
      team
    end
  end

  @doc """
  Get the total number of votes for a team.
  """
  def num_votes(team) do
    Kernel.map_size(team.votes)
  end

  @doc """
  Get the total number of a certain vote for a team.
  """
  def num_votes(team, vote) do
    Enum.count(team.votes, fn {_, v} -> v == vote end)
  end

  def hide_votes(team) do
    filtered_votes = Enum.map(team.votes, fn {p, v} -> {p, "unknown"} end)

    %{team | votes: filtered_votes}
  end
end
