# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :avalon,
  ecto_repos: [Avalon.Repo]

# Configures the endpoint
config :avalon, Avalon.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RrQv0VkNjVMf7rkSYkQGN+Yvnw9P2XT2zvPYwb3TD3PQtJ/5iqHWyIECw3ZYhZi1",
  render_errors: [view: Avalon.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Avalon.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
