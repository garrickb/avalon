defmodule Avalon.FsmGameState do
  use Fsm, initial_state: :waiting, initial_data: %Avalon.FsmGameData{}

  alias Avalon.FsmGameData
  alias Avalon.FsmState.Waiting, as: Waiting
  alias Avalon.FsmState.SelectQuestMembers, as: SelectQuestMembers

  # Waiting for players to join the room.
  defstate waiting do

    # Start the game by having the king form a team
    defevent start_game do
      next_state(:select_quest_members)
    end
  end

  # Waiting for king to select players to go on the quest
  defstate select_quest_members do

    # Team was selected; wait for players to vote on the team
    defevent selected do
      next_state(:vote_on_members)
    end
  end

  # Waiting on all players to cast their vote on the current team composition
  defstate vote_on_members do

    defevent reject, data: fsm_data do
      reject_count = fsm_data.reject_count + 1
      fsm_data = %FsmGameData{fsm_data | reject_count: reject_count}

      cond do
        reject_count >= 5 ->
          next_state(:evil_wins, fsm_data)

        reject_count ->
          next_state(:select_quest_members, fsm_data)
        end
    end

    # Team was accepted
    defevent accept, data: fsm_data do
      fsm_data = %FsmGameData{fsm_data | reject_count: 0}
      next_state(:go_on_quest, fsm_data)
    end
  end

  # Waiting for the team members to select a failure or success card
  defstate go_on_quest do

    # Quest was failed
    defevent fail, data: fsm_data do
      failed_count = fsm_data.failed_count + 1
      fsm_data = %FsmGameData{fsm_data | failed_count: failed_count}

      cond do
        failed_count >= 3 ->
          next_state(:evil_wins, fsm_data)

        failed_count ->
          next_state(:select_quest_members, fsm_data)
      end
    end

    # Quest was succeeded
    defevent succeed, data: fsm_data do
      succeeded_count = fsm_data.succeeded_count + 1
      fsm_data = %FsmGameData{fsm_data | succeeded_count: succeeded_count}

      cond do
        succeeded_count >= 3 ->
          next_state(:good_wins, fsm_data)

        succeeded_count ->
          next_state(:select_quest_members, fsm_data)
      end
    end
  end

  # Minions of Mordred win
  defstate evil_wins do
    # Play another game?
    defevent restart do
      next_state(:waiting, %Avalon.FsmGameData{})
    end
  end

  # Loyal Servants of Arthur win.
  defstate good_wins do
    # Play another game?
    defevent restart do
      next_state(:waiting, %Avalon.FsmGameData{})
    end
  end
end
