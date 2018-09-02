defmodule Avalon.Presence do
  use Phoenix.Presence, otp_app: :my_app,
                      pubsub_server: Avalon.PubSub
end
