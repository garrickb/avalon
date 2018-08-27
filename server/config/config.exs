# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :avalon, AvalonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ZwVpSOz48TJIy6Oeyut9BnOmlY8Ww2zbxU2/+/+iQ72VAjOn74o2Zj5dAYwcfqY1",
  render_errors: [view: AvalonWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Avalon.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
