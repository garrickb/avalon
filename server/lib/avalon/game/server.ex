defmodule Avalon.Game.Server do
  @moduledoc """
  A game server process that holds a `Game` struct as its state.
  """

  use GenServer
  require Logger

  @timeout :timer.hours(1)

  # Client Interface

  @doc """
  Spawns a new game server process registered under the given `game_name`.
  """
  def start_link(game_name, players) do
    name = via_tuple(game_name)
    GenServer.start_link(__MODULE__, {game_name, players}, name: name)
  end

  def summary(game_name) do
    GenServer.call(via_tuple(game_name), :summary)
  end

  @doc """
  Returns a tuple used to register and lookup a game server process by name.
  """
  def via_tuple(game_name) do
    {:via, Registry, {Avalon.GameRegistry, game_name}}
  end

  @doc """
  Returns the `pid` of the game server process registered under the
  given `game_name`, or `nil` if no process is registered.
  """
  def game_pid(game_name) do
    game_name
    |> via_tuple()
    |> GenServer.whereis()
  end

  # Server Callbacks

  def init({game_name, players}) do
    game =
      case :ets.lookup(:games_table, game_name) do
        [] ->
          game = Avalon.Game.new(game_name, players)
          :ets.insert(:games_table, {game_name, game})
          game

        [{^game_name, game}] ->
          game
    end

    Logger.info("Initializing game server '#{game_name}'.")

    {:ok, game, @timeout}
  end

  def handle_call(:summary, _from, game) do
    {:reply, game, game, @timeout}
  end

  def handle_info(:timeout, game) do
    game_name = my_game_name()

    Logger.info("Game '#{game_name}' has timed out")
    {:stop, {:shutdown, :timeout}, game}
  end

  def terminate({:shutdown, :timeout}, _game) do
    game_name = my_game_name()

    Logger.info("Terminating game server process '#{game_name}'")
    :ets.delete(:games_table, game_name)
    :ok
  end

  def terminate(_reason, _game) do
    game_name = my_game_name()

    Logger.info("Game '#{game_name}' terminated")
    :ok
  end

  defp my_game_name do
    Registry.keys(Avalon.GameRegistry, self()) |> List.first
  end
end
