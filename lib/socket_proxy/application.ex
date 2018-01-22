defmodule SocketProxy.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting SocketProxy.Application")

    listen_port = Application.get_env(:socket_proxy, :listen_port) || 4000
    destinations = Application.get_env(:socket_proxy, :destinations) || []

    children = if Mix.env == :test do
      []
    else
      [
        {SocketProxy, {listen_port, destinations}},
        {SocketProxy.ReceiverSupervisor, []}
      ]
    end

    opts = [strategy: :one_for_all, name: SocketProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
