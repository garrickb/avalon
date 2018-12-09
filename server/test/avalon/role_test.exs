defmodule Avalon.RoleTest do
  use ExUnit.Case

  alias Avalon.Role, as: Role

  test "creating generic good" do
    role = Role.new(:servant)
    assert role.alignment == :good
  end

  test "creating generic bad" do
    role = Role.new(:minion)
    assert role.alignment == :evil
  end

  test "creating merlin" do
    role = Role.new(:merlin)
    assert role.alignment == :good
  end

  test "creating assassin" do
    role = Role.new(:assassin)
    assert role.alignment == :evil
  end

  test "creating percival" do
    role = Role.new(:percival)
    assert role.alignment == :good
  end

  test "creating mordred" do
    role = Role.new(:mordred)
    assert role.alignment == :evil
  end

  test "creating oberon" do
    role = Role.new(:oberon)
    assert role.alignment == :evil
  end

  test "creating morgana" do
    role = Role.new(:morgana)
    assert role.alignment == :evil
  end

  test "pad roles with exact number of settings set" do
    roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant), Role.new(:servant)]

    assert roles |> Role.pad(2, 2) == roles
  end

  test "pad roles with missing good role" do
    roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant), Role.new(:servant)]
    expected_roles = roles ++ [Role.new(:servant)]

    assert roles |> Role.pad(2, 3) == expected_roles
  end

  test "pad roles with missing bad role" do
    roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant), Role.new(:servant)]
    expected_roles = [Role.new(:minion)] ++ roles

    assert roles |> Role.pad(3, 2) == expected_roles
  end

  test "too many evil roles is padded down" do
    roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant), Role.new(:servant)]
    expected_roles = [Role.new(:minion), Role.new(:servant), Role.new(:servant)]

    assert roles |> Role.pad(1, 2) == expected_roles
  end

  test "too many good roles is padded down" do
    roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant), Role.new(:servant)]
    expected_roles = [Role.new(:minion), Role.new(:minion), Role.new(:servant)]

    assert roles |> Role.pad(2, 1) == expected_roles
  end

  test "merlin can see evil, except mordred" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Merlin can see all evil (minus mordred)
    evil_role = Role.new(:unknown, :evil)
    all_roles = [minion, assassin, oberon, morgana]
    merlin |> assert_peek(all_roles, evil_role)

    # Merlin cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, merlin, mordred, percival]
    merlin |> assert_peek(all_roles, unknown_role)
  end

  test "assassin can see evil, except oberon" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Assassin can see all evil (minus oberon)
    evil_role = Role.new(:unknown, :evil)
    all_roles = [minion, assassin, mordred, morgana]
    assassin |> assert_peek(all_roles, evil_role)

    # Assassin cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, merlin, oberon, percival]
    assassin |> assert_peek(all_roles, unknown_role)
  end

  test "percival can see merlin and morgana" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Percival sees merlin and morgana as merlin
    merlin_roles = [merlin, morgana]
    percival |> assert_peek(merlin_roles, merlin)

    # Percival cannot see any other role's information
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [assassin, percival, mordred, oberon, servant, minion]
    percival |> assert_peek(all_roles, unknown_role)
  end

  test "mordred can see all evil, except for oberon" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Mordred can see all evil (minus oberon)
    evil_role = Role.new(:unknown, :evil)
    all_roles = [minion, assassin, mordred, morgana]
    mordred |> assert_peek(all_roles, evil_role)

    # Mordred cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, merlin, oberon, percival]
    mordred |> assert_peek(all_roles, unknown_role)
  end

  test "morgana can see all evil, except for oberon" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Morgana can see all evil (minus oberon)
    evil_role = Role.new(:unknown, :evil)
    all_roles = [minion, assassin, mordred, morgana]
    morgana |> assert_peek(all_roles, evil_role)

    # Morgana cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, merlin, oberon, percival]
    morgana |> assert_peek(all_roles, unknown_role)
  end

  test "oberon is not known by evil, nor does he know evil" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Oberon cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [minion, assassin, mordred, morgana, servant, merlin, oberon, percival]
    oberon |> assert_peek(all_roles, unknown_role)
  end

  test "servant cannot see any other role's information" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Servant cannot see any role's information
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, minion, merlin, assassin, mordred, oberon, morgana, percival]
    servant |> assert_peek(all_roles, unknown_role)
  end

  test "minion can see all evil, except for oberon" do
    merlin = Role.new(:merlin)
    assassin = Role.new(:assassin)
    percival = Role.new(:percival)
    mordred = Role.new(:mordred)
    oberon = Role.new(:oberon)
    morgana = Role.new(:morgana)
    servant = Role.new(:servant)
    minion = Role.new(:minion)

    # Minion can see all evil (minus oberon)
    evil_role = Role.new(:unknown, :evil)
    all_roles = [minion, assassin, mordred, morgana]
    minion |> assert_peek(all_roles, evil_role)

    # Minion cannot see any info for other roles
    unknown_role = Role.new(:unknown, :unknown)
    all_roles = [servant, merlin, oberon, percival]
    minion |> assert_peek(all_roles, unknown_role)
  end

  # Assert that a peek results in the expected role for an array of targets
  defp assert_peek(self, targets, expected) when is_list(targets) do
    Enum.map(
      targets,
      fn target ->
        assert_peek(self, target, expected)
      end
    )
  end

  # Assert that a peek results in the expected role for a given target
  defp assert_peek(self, target, expected) do
    result = Role.peek(self, target)

    assert(
      result == expected,
      "#{self.name} peeking at #{target.name} should result in:" <>
        "\n\tExpected:\t(#{expected.name}, #{expected.alignment})" <>
        "\n\tGot:\t\t(#{result.name}, #{result.alignment})"
    )
  end
end
