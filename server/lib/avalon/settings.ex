defmodule Avalon.Settings do
  defstruct [:merlin, :assassin, :percival, :mordred, :oberon, :morgana]

  alias Avalon.Settings

  require Logger

  @doc """
  Creates a new lobby
  """
  def new() do
    %Settings{
      merlin: true,
      assassin: true,
      percival: false,
      mordred: false,
      oberon: false,
      morgana: false
    }
  end

  @doc """
  sets a settings value
  """
  def set(settings, setting_name, value) when is_binary(setting_name) and is_boolean(value) do
    case String.downcase(setting_name) do
      "merlin" ->
        %{settings | merlin: value}

      "assassin" ->
        %{settings | assassin: value}

      "percival" ->
        %{settings | percival: value}

      "mordred" ->
        %{settings | oberon: value}

      "oberon" ->
        %{settings | oberon: value}

      "morgana" ->
        %{settings | morgana: value}

      _ ->
        Logger.warn("Attempted to set unknown setting '#{setting_name}' to '#{value}'")
        settings
    end
  end
end
