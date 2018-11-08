defmodule Avalon.Quest do
  @enforce_keys [:num_players, :num_fails_required, :outcome, :selected_players]
  defstruct [:num_players, :num_fails_required, :outcome, :selected_players]

  alias Avalon.Quest

  require Logger

  @doc """
  Creates a new quest.
  """
  def new(num_players, num_fails_required)
      when is_number(num_players) and is_number(num_fails_required) do
    %Quest{
      num_players: num_players,
      num_fails_required: num_fails_required,
      outcome: {:uncompleted},
      selected_players: []
    }
  end

  @doc """
  Returns the quests for a given number of players.
  """
  def get_quests(num_players) when is_number(num_players) do
    case num_players do
      5 ->
        [
          new(2, 1),
          new(3, 1),
          new(2, 1),
          new(3, 1),
          new(3, 1)
        ]

      6 ->
        [
          new(2, 1),
          new(3, 1),
          new(4, 1),
          new(3, 1),
          new(4, 1)
        ]

      7 ->
        [
          new(2, 1),
          new(3, 1),
          new(3, 1),
          new(4, 2),
          new(4, 1)
        ]

      8 ->
        [
          new(3, 1),
          new(4, 1),
          new(4, 1),
          new(5, 2),
          new(5, 1)
        ]

      9 ->
        [
          new(3, 1),
          new(4, 1),
          new(4, 1),
          new(5, 2),
          new(5, 1)
        ]

      10 ->
        [
          new(3, 1),
          new(4, 1),
          new(4, 1),
          new(5, 2),
          new(5, 1)
        ]

      _ ->
        if num_players < 5 do
          [
            new(2, 1),
            new(3, 1),
            new(2, 1),
            new(3, 1),
            new(3, 1)
          ]
        else
          [
            new(3, 1),
            new(4, 1),
            new(4, 1),
            new(5, 2),
            new(5, 1)
          ]
        end
    end
  end

  @doc """
  Mark a player as selected.
  """
  def select_player(quest, player_name) when is_binary(player_name) do
    if quest.outcome == {:uncompleted} do
      if quest.selected_players |> Enum.member?(player_name) do
        quest
      else
        # If we would go over the limit of players by adding this player,
        # then we should remove the first player that was selected
        new_selected_players =
          if length(quest.selected_players) + 1 > quest.num_players do
            [_ | players] = quest.selected_players
            players ++ [player_name]
          else
            quest.selected_players ++ [player_name]
          end

        %{quest | selected_players: new_selected_players}
      end
    else
      Logger.warn(
        "Attempted to select player '#{player_name}' in already completed quest: #{inspect(quest)}"
      )

      quest
    end
  end

  @doc """
  Mark a player as unselected.
  """
  def deselect_player(quest, player_name) when is_binary(player_name) do
    if quest.outcome == {:uncompleted} do
      if Enum.member?(quest.selected_players, player_name) do
        %{
          quest
          | selected_players: quest.selected_players |> Enum.filter(fn n -> n != player_name end)
        }
      else
        quest
      end
    else
      Logger.warn(
        "Attempted to deselect player '#{player_name}' in already" <>
          "completed quest: #{inspect(quest)}"
      )

      quest
    end
  end

  @doc """
  Returns the final state of a quest after completion.
  """
  def complete(quest, num_fails) when is_number(num_fails) do
    result = if num_fails >= quest.num_fails_required, do: :failure, else: :success
    %{quest | outcome: {result, num_fails}}
  end
end
