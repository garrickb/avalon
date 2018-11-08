defmodule Avalon do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Avalon.Game.Registry},
      Avalon.Game.Supervisor
    ]

    :ets.new(:games_table, [:public, :named_table])
    Logger.info("Created ETS")

    opts = [strategy: :one_for_one, name: Avalon.Game.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
