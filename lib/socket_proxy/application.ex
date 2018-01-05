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
        {SocketProxy.Dispatcher, []},
        {SocketProxy.Listener, [port: listen_port]},
      ] ++ supervisor_spec_for_destinations(destinations)
    end

    opts = [strategy: :one_for_all, name: SocketProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp supervisor_spec_for_destinations(destinations) do
    destinations
    |> Enum.with_index
    |> Enum.map(fn {dst, i} ->
      Supervisor.child_spec({SocketProxy.Sender, ip_port: dst}, id: :"socket_proxy_sender_#{i}")
    end)
  end
end
