use Mix.Config

config :socket_proxy,
  start_children?: false,
  staleness_check_interval_ms: 3_000
