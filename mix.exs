defmodule SocketProxy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :socket_proxy,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SocketProxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ehmon, git: "https://github.com/mbta/ehmon.git"},
      {:logger_splunk_backend, github: "mbta/logger_splunk_backend"}
    ]
  end
end
