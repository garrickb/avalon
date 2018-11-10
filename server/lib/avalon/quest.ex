defmodule Avalon.Quest do
  @enforce_keys [
    :id,
    :state,
    :team,
    :num_fails_required,
    :quest_cards
  ]
  defstruct [
    :id,
    :state,
    :team,
    :num_fails_required,
    :quest_cards
  ]

  alias Avalon.Quest
  alias Avalon.Team

  require Logger

  @doc """
  Creates a new quest.
  """
  def new(id, num_players_required, num_fails_required)
      when is_number(num_players_required) and is_number(num_fails_required) do
    %Quest{
      id: id,
      state: :uncompleted,
      team: Team.new(num_players_required),
      num_fails_required: num_fails_required,
      quest_cards: %{}
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
    if quest.state == :uncompleted do
      %{quest | team: quest.team |> Team.add_player(player_name)}
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
    if quest.state == :uncompleted do
      %{quest | team: quest.team |> Team.remove_player(player_name)}
    else
      Logger.warn(
        "Attempted to deselect player '#{player_name}' in already completed quest: #{
          inspect(quest)
        }"
      )

      quest
    end
  end

  @doc """
  returns the active quest (first uncompleted)
  """
  def get_active_quest(quests) do
    Enum.find(quests, fn quest -> :uncompleted == quest.state end)
  end

  @doc """
  returns whether or not voting on the current team can begin
  """
  def voting_can_begin?(quest) do
    quest.team |> Team.has_num_players_required?()
  end

  @doc """
  player accepts the selected players for the current team
  """
  def player_accept_vote(quest, player_name) do
    if quest.state == :uncompleted do
      %{quest | team: Team.player_vote(quest.team, player_name, :accept)}
    else
      Logger.warn(
        "Player '#{player_name}' cannot accept team from a quest in state '#{quest.state}'"
      )

      quest
    end
  end

  @doc """
  player rejects the selected players for the current team
  """
  def player_reject_vote(quest, player_name) do
    if quest.state == :uncompleted do
      %{quest | team: Team.player_vote(quest.team, player_name, :reject)}
    else
      Logger.warn(
        "Player '#{player_name}' cannot reject team from a quest in state '#{quest.state}'"
      )

      quest
    end
  end

  @doc """
  returns whether voting is done, based on the expected number of votes
  """
  def team_done_voting?(quest, num_players) when is_number(num_players) do
    Team.num_votes(quest.team) == num_players
  end

  @doc """
  returns whether the accepts outnumber the rejects on a team vote
  """
  def team_voting_passed?(quest) do
    Team.num_votes(quest.team, :accept) > Team.num_votes(quest.team, :reject)
  end

  @doc """
  clears the vote history to start fresh
  """
  def team_clear_votes(quest) do
    new_team = %{quest.team | votes: %{}}
    %{quest | team: new_team}
  end

  def player_quest_card(quest, player_name, card) do
    if quest.state == :uncompleted do
      if quest.team |> Team.on_team?(player_name) do
        new_quest_cards =
          quest.quest_cards
          |> Map.put(player_name, card)

        if new_quest_cards |> Kernel.map_size() == quest.team.num_players_required do
          # Received last quest card. Store result of quest.
          num_fails = new_quest_cards |> Enum.count(fn {_, qc} -> qc == :fail end)
          new_state = if num_fails >= quest.num_fails_required, do: :failure, else: :success
          %{quest | state: new_state, quest_cards: new_quest_cards}
        else
          %{quest | quest_cards: new_quest_cards}
        end
      else
        Logger.warn("Player '#{player_name}' not on team cannot play quest card")
        quest
      end
    else
      Logger.warn(
        "Player '#{player_name}' cannot play quest card '#{card}' from a quest" <>
          " in state '#{quest.state}'"
      )

      quest
    end
  end

  @doc """
  returns whether voting is done, based on the expected number of card
  """
  def quest_done_playing?(quest) do
    length(quest.team.players) == Kernel.map_size(quest.quest_cards)
  end

  @doc """
  returns whether the accepts outnumber the rejects on a team vote
  """
  def quest_passed?(quest) do
    quest.state != :failure
  end

  @doc """
  updates the list of quests with the new quest based on the quest id
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
