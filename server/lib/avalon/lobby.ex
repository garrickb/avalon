defmodule Avalon.Lobby do
  @enforce_keys [:id]
  defstruct [:id, :settings, :game]

  alias Avalon.Lobby
  alias Avalon.Settings

  require Logger

  @doc """
  Creates a new lobby
  """
  def new(id) when is_binary(id) do
    %Lobby{id: id, settings: Settings.new()}
  end
end
