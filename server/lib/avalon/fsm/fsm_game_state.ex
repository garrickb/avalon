defmodule Avalon.FsmGameState do
  use Fsm, initial_state: :waiting, initial_data: %Avalon.FsmGameData{}

  alias Avalon.FsmGameData

  require Logger

  # Waiting for players to join the room.
  defstate waiting do
    # Start the game by having the king form a team
    defevent start_game do
      Logger.info("FSM: Starting Game")
      next_state(:build_team)
    end
  end

  # Waiting for king to select players to go on the quest
  defstate build_team do
    # Team was selected; wait for players to vote on the team
    defevent begin_voting do
      Logger.info("FSM: Team members are selected")
      next_state(:team_vote)
    end
  end

  # Waiting on all players to cast their vote on the current team composition
  defstate team_vote do
    defevent reject, data: fsm_data do
      reject_count = fsm_data.reject_count + 1
      fsm_data = %FsmGameData{fsm_data | reject_count: reject_count}

      cond do
        reject_count >= 5 ->
          Logger.info("FSM: Team members were rejected, and evil wins")
          next_state(:game_end_evil, fsm_data)

        reject_count ->
          Logger.info("FSM: Team members were rejected #{reject_count} times")
          next_state(:build_team, fsm_data)
      end
    end

    # Team was accepted
    defevent accept, data: fsm_data do
      Logger.info("FSM: Team members were accepted")
      fsm_data = %FsmGameData{fsm_data | reject_count: 0}
      next_state(:quest, fsm_data)
    end
  end

  # Waiting for the team members to select a failure or success card
  defstate quest do
    # Quest was failed
    defevent fail, data: fsm_data do
      failed_count = fsm_data.failed_count + 1
      fsm_data = %FsmGameData{fsm_data | failed_count: failed_count}

      cond do
        failed_count >= 3 ->
          Logger.info("FSM: Quest was failed, and evil wins")
          next_state(:game_end_evil, fsm_data)

        failed_count ->
          Logger.info("FSM: Quest was failed")
          next_state(:build_team, fsm_data)
      end
    end

    # Quest was succeeded
    defevent succeed, data: fsm_data do
      succeeded_count = fsm_data.succeeded_count + 1
      fsm_data = %FsmGameData{fsm_data | succeeded_count: succeeded_count}

      cond do
        succeeded_count >= 3 ->
          Logger.info("FSM: Quest was successful, and good wins")
          next_state(:game_end_good, fsm_data)

        succeeded_count ->
          Logger.info("FSM: Quest was successful")
          next_state(:build_team, fsm_data)
      end
    end

    # Quest was succeeded (With Assassin + Merlin)
    defevent succeed_with_assassin_and_merlin, data: fsm_data do
      succeeded_count = fsm_data.succeeded_count + 1
      fsm_data = %FsmGameData{fsm_data | succeeded_count: succeeded_count}

      cond do
        succeeded_count >= 3 ->
          Logger.info(
            "FSM: Quest was successful, and good wins? Allowing the assassin to guess Merlin."
          )

          next_state(:game_end_good_assassin, fsm_data)

        succeeded_count ->
          Logger.info("FSM: Quest was successful (with assassin and merlin)")
          next_state(:build_team, fsm_data)
      end
    end
  end

  # Minions of Mordred win
  defstate game_end_evil do
    # Play another game?
    defevent restart do
      Logger.info("FSM: Restarting game after evil win")
      next_state(:waiting, %Avalon.FsmGameData{})
    end
  end

  # Loyal Servants of Arthur win, but there is Merlin + Assassin in game.
  # And the Assassin can guess who Merlin is
  defstate game_end_good_assassin do
    # Play another game?
    defevent correct_assassination, data: fsm_data do
      Logger.info("FSM: Assassin guessed correctly. Evil win.")
      next_state(:game_end_evil, fsm_data)
    end

    defevent incorrect_assassination, data: fsm_data do
      Logger.info("FSM: Assassin guessed incorrectly. Good win.")
      next_state(:game_end_good, fsm_data)
    end
  end

  # Loyal Servants of Arthur win.
  defstate game_end_good do
    # Play another game?
    defevent restart do
      Logger.info("FSM: Restarting game after good win")
      next_state(:waiting, %Avalon.FsmGameData{})
    end
  end
end
