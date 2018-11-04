defmodule Avalon.Game.Supervisor do
  @moduledoc """
  A supervisor that starts `Server` processes dynamically.
  """

  use DynamicSupervisor
  require Logger
  alias Avalon.Game.Server, as: GameServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
  @doc """
  Starts a `Server` process and supervises it.
  """
  def start_game(game_name, players) do
    Logger.info("Supervising new game: '#{game_name} with players: #{inspect(players)}'")

    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [game_name, players]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminates the `Server` process normally. It won't be restarted.
  """
  def stop_game(game_name) do
    Logger.info("Stopping game: '#{game_name}'")

    :ets.delete(:games_table, game_name)
    
    child_pid = GameServer.game_pid(game_name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
