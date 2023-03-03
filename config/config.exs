# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :webbait,
  namespace: WebBait,
  ecto_repos: [WebBait.Repo]

# Configures the endpoint
config :webbait, WebBaitWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: WebBaitWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: WebBait.PubSub,
  live_view: [signing_salt: "GfnM+zu9"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind, version: "3.2.4", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
  cd: Path.expand("../assets", __DIR__)
]

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info],
    # Silence irrelevant warnings caused by resending handshake events
    [module: Membrane.SRTP.Encryptor, function: "handle_event/4", level_lower_than: :error],
    [module: MDNS.Client, level_lower_than: :error]
  ]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :membrane_telemetry_metrics, enabled: true

config :membrane_opentelemetry, enabled: true

config :membrane_rtc_engine_timescaledb, repo: WebBait.Repo

config :membrane_core, use_push_flow_control: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
