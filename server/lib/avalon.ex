defmodule Avalon do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Avalon.Room.Registry},
      Avalon.Room.Supervisor
    ]

    :ets.new(:rooms_table, [:public, :named_table])
    Logger.info("Created ETS")

    opts = [strategy: :one_for_one, name: Avalon.Room.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
