# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :mail_sniffex,
  smtp_opts: [{:port, System.get_env("SMTP_PORT") || 2525}],
  size_limit: System.get_env("SIZE_LIMIT") || 1_000_000_000,
  environment: Mix.env()

# Configures the endpoint
config :mail_sniffex, MailSniffexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7OywbcXzL4ZJFU8FAjxH/nBpTcHgdXfqrXobBmupGdu45UlCyB9ndxjqWtUPR7RP",
  render_errors: [view: MailSniffexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MailSniffex.PubSub,
  live_view: [signing_salt: "z3SOukXy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
