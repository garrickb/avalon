defmodule Avalon.SettingsTest do
  use ExUnit.Case

  alias Avalon.Settings, as: Settings

  test "creating new settings" do
    settings = Settings.new()

    assert settings.merlin == true
  end

  test "set setting value" do
    settings =
      Settings.new()
      |> Settings.set("merlin", false)

    assert settings.merlin == false
  end

  test "set setting value is case insensitive" do
    settings =
      Settings.new()
      |> Settings.set("MeRlIn", false)

    assert settings.merlin == false
  end

  test "set setting with invalid name" do
    settings =
      Settings.new()
      |> Settings.set("marvin", false)

    assert settings == Settings.new()
  end
end
