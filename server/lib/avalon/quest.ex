defmodule Avalon.Quest do
  @enforce_keys [
    :id,
    :num_players_required,
    :num_fails_required,
    :outcome,
    :num_fails,
    :selected_players,
    :votes
  ]
  defstruct [
    :id,
    :num_players_required,
    :num_fails_required,
    :outcome,
    :num_fails,
    :selected_players,
    :votes
  ]

  alias Avalon.Quest

  require Logger

  @doc """
  Creates a new quest.
  """
  def new(id, num_players_required, num_fails_required)
      when is_number(num_players_required) and is_number(num_fails_required) do
    %Quest{
      id: id,
      num_players_required: num_players_required,
      num_fails_required: num_fails_required,
      outcome: :uncompleted,
      num_fails: nil,
      selected_players: [],
      votes: %{}
    }
  end

  @doc """
  Returns the quests for a given number of players.
  """
  def get_quests(num_players) when is_number(num_players) do
    case num_players do
      5 ->
        [
          {2, 1},
          {3, 1},
          {2, 1},
          {3, 1},
          {3, 1}
        ]

      6 ->
        [
          {2, 1},
          {3, 1},
          {4, 1},
          {3, 1},
          {4, 1}
        ]

      7 ->
        [
          {2, 1},
          {3, 1},
          {3, 1},
          {4, 2},
          {4, 1}
        ]

      8 ->
        [
          {3, 1},
          {4, 1},
          {4, 1},
          {5, 2},
          {5, 1}
        ]

      9 ->
        [
          {3, 1},
          {4, 1},
          {4, 1},
          {5, 2},
          {5, 1}
        ]

      10 ->
        [
          {3, 1},
          {4, 1},
          {4, 1},
          {5, 2},
          {5, 1}
        ]

      _ ->
        if num_players < 5 do
          [
            {2, 1},
            {3, 1},
            {2, 1},
            {3, 1},
            {3, 1}
          ]
        else
          [
            {3, 1},
            {4, 1},
            {4, 1},
            {5, 2},
            {5, 1}
          ]
        end
    end
    |> Enum.with_index()
    |> Enum.map(fn {params, i} -> new(i, Kernel.elem(params, 0), Kernel.elem(params, 1)) end)
  end

  @doc """
  Mark a player as selected.
  """
  def select_player(quest, player_name) when is_binary(player_name) do
    if quest.outcome == :uncompleted do
      if quest.selected_players |> Enum.member?(player_name) do
        quest
      else
        # If we would go over the limit of players by adding this player,
        # then we should remove the first player that was selected
        new_selected_players =
          if length(quest.selected_players) + 1 > quest.num_players_required do
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
    if quest.outcome == :uncompleted do
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
        "Attempted to deselect player '#{player_name}' in already " <>
          "completed quest: #{inspect(quest)}"
      )

      quest
    end
  end

  @doc """
  returns the active quest
  """
  def get_active_quest(quests) do
    Enum.find(quests, fn quest ->
      match?(:uncompleted, quest.outcome)
    end)
  end

  @doc """
  returns whether or not voting on the quest can begin
  """
  def voting_can_begin?(quest) do
    length(quest.selected_players) == quest.num_players_required
  end

  @doc """
  player accepts the selected players
  """
  def vote_accept(quest, player_name) do
    new_votes = Map.put(quest.votes, player_name, :accept)
    %{quest | votes: new_votes}
  end

  @doc """
  player rejects the selected players
  """
  def vote_reject(quest, player_name) do
    new_votes = Map.put(quest.votes, player_name, :reject)
    %{quest | votes: new_votes}
  end

  @doc """
  returns whether or not voting is finished
  """
  def all_players_voted?(quest, num_players) do
    Kernel.map_size(quest.votes) == num_players
  end

  @doc """
  returns the number of votes which are rejects
  """
  def number_of_reject_votes(quest) do
    Enum.count(quest.votes, fn {_, v} -> v == :reject end)
  end

  @doc """
  Returns the final state of a quest after completion.
  """
  def complete(quest, num_fails) when is_number(num_fails) do
    result = if num_fails >= quest.num_fails_required, do: :failure, else: :success
    %{quest | outcome: result, num_fails: num_fails}
  end

  @doc """
  updates the list of quests with the new quest, based on the id
  """
  def update_quest(new_quest, quests) do
    Enum.map(quests, fn quest ->
      if quest.id == new_quest.id do
        new_quest
      else
        quest
      end
    end)
  end
end
