defmodule Avalon.Player do
  @enforce_keys [:name, :role]
  defstruct [:name, :role, :ready, :king]

  alias Avalon.Player

  require Logger

  @doc """
  Creates a list of players with random roles.
  """
  def newFromList(names, roles) when is_list(names) and is_list(roles) do
    Stream.zip(names, roles) |> Enum.map(fn {n, r} -> new(n, r) end)
  end

  @doc """
  Creates a new player.
  """
  def new(name, role) when is_binary(name) do
    %Player{name: name, role: role, ready: false, king: false}
  end

  @doc """
  Mark a player as ready.
  """
  def ready(player) do
    %{player | ready: true}
  end

  @doc """
  returns whether or not all players are already
  """
  def all_players_ready?(players) do
    players |> Enum.all?(fn p -> p.ready == true end)
  end

  @doc """
  Sets a random player to be king
  """
  def set_random_king(players) do
    king = Enum.random(players)
    players |> Enum.map(fn p -> %{p | king: p == king} end)
  end

  @doc """
  Sets the king to the next player, defaults to the first player if there
  is no current king.
  """
  def set_next_king(players) do
    next_king_index =
      rem((players |> Enum.find_index(fn p -> p.king == true end) || -1) + 1, length(players))

    players
    |> Stream.with_index()
    |> Enum.map(fn {player, index} -> %{player | king: index == next_king_index} end)
  end

  @doc """
  return the current king
  """
  def get_king(players) do
    Enum.find(players, fn p -> p.king end)
  end

  @doc """
  check if a player is king
  """
  def is_king?(players, player) do
    Enum.any?(players, fn p -> p.king && p.name == player end)
  end

  @doc """
  check if a player is the assassin
  """
  def is_assassin?(players, player) do
    Enum.any?(players, fn p -> p.role.name == :assassin && p.name == player end)
  end

  @doc """
  check if a player is the assassin
  """
  def is_merlin?(players, player) do
    Enum.any?(players, fn p -> p.role.name == :merlin && p.name == player end)
  end

  def handle_out(player, requester) do
    if requester == nil do
      spectator = Avalon.Role.new(:spectator, :spectator)
      %{player | role: Avalon.Role.peek(spectator, player.role)}
    else
      if player.name != requester.name,
        do: %{player | role: Avalon.Role.peek(requester.role, player.role)},
        else: player
    end
  end
end
