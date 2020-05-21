use Mix.Config

config :logger, backends: [{Logger.Backend.Splunk, :splunk_log}, :console]

config :logger, :splunk_log,
  host: "https://http-inputs-mbta.splunkcloud.com/services/collector/event",
  token: {:system, "SOCKET_PROXY_SPLUNK_TOKEN"},
  format: "$dateT$time $metadata[$level] node=$node $message\n",
  level: :info,
  max_buffer: 1
