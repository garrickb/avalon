defmodule Avalon.Player do
  use GenServer

  # Client

  def start_link(_default) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server

  def init(state) do
    {:ok, state}
  end

  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end
end
