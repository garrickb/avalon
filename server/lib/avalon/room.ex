defmodule Avalon.Room do
  @enforce_keys [:id]
  defstruct [:id, :settings, :game]

  alias Avalon.Room
  alias Avalon.Settings

  require Logger

  @doc """
  Creates a new room
  """
  def new(id) when is_binary(id) do
    %Room{id: id, settings: Settings.new()}
  end

  @doc """
  Begins the game
  """
  def start_game(room, players) do
    %{room | game: Avalon.Game.new(players, room.settings)}
  end

  @doc """
  Stops the game
  """
  def stop_game(room) do
    %{room | game: nil}
  end

  @doc """
  Sets a setting value
  """
  def set_setting(room, setting_name, setting_value) do
    new_settings = Avalon.Settings.set(room.settings, setting_name, setting_value)
    %{room | settings: new_settings}
  end
end
