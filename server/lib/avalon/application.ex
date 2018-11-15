defmodule Avalon.Application do
  use Application
  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(AvalonWeb.Endpoint, []),
      AvalonWeb.Presence,
      {Registry, keys: :unique, name: Avalon.Room.Registry},
      Avalon.Room.Supervisor
    ]

    :ets.new(:rooms_table, [:public, :named_table])

    opts = [strategy: :one_for_one, name: Avalon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AvalonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
