defmodule AvalonWeb.Presence do
  use Phoenix.Presence,
  otp_app: :avalon_web,
  pubsub_server: AvalonWeb.PubSub
end
