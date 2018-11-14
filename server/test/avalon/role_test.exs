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
end
