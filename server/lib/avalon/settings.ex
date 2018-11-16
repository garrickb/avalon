defmodule Avalon.Settings do
  defstruct [:merlin, :assassin, :percival, :mordred, :oberon, :morgana]

  alias Avalon.Settings
  alias Avalon.Role, as: Role

  require Logger

  @doc """
  Create new settings
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

  def get_roles(settings) do
    [:merlin, :assassin, :percival, :mordred, :oberon, :morgana]
    |> Enum.filter(fn role_name -> settings |> get(role_name) end)
    |> Stream.map(fn role_name -> Role.new(role_name) end)
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
        %{settings | mordred: value}

      "oberon" ->
        %{settings | oberon: value}

      "morgana" ->
        %{settings | morgana: value}

      _ ->
        Logger.warn("Attempted to set unknown setting '#{setting_name}' to '#{value}'")
        settings
    end
  end

  @doc """
  Gets a setting. Returns false if it is invalid.
  """
  def get(settings, setting) do
    case setting do
      :merlin ->
        settings.merlin

      :assassin ->
        settings.assassin

      :percival ->
        settings.percival

      :mordred ->
        settings.mordred

      :oberon ->
        settings.oberon

      :morgana ->
        settings.morgana
    end
  end
end
