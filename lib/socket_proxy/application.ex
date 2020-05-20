defmodule SocketProxy.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    if Application.get_env(:socket_proxy, :start_children?) do
      Logger.info("Starting SocketProxy.Application")

      listen_port = Application.get_env(:socket_proxy, :listen_port) || get_listen_port()
      destinations = Application.get_env(:socket_proxy, :destinations) || get_destinations()

      children = [
        {SocketProxy, {listen_port, destinations}},
        {SocketProxy.ReceiverSupervisor, []}
      ]

      opts = [strategy: :one_for_all, name: SocketProxy.Supervisor]
      Supervisor.start_link(children, opts)
    else
      Supervisor.start_link([], strategy: :one_for_all, name: SocketProxy.Supervisor)
    end
  end

  defp get_listen_port do
    "SOCKET_PROXY_LISTEN_PORT"
    |> System.get_env()
    |> String.to_integer
  end

  defp get_destinations do
    "SOCKET_PROXY_DESTINATIONS"
    |> System.get_env()
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_ip_port/1)
  end

  defp parse_ip_port(ip_port) do
    [raw_host, raw_port] = String.split(ip_port, ":")
    port = String.to_integer(raw_port)
    host = String.to_charlist(raw_host)
    {host, port}
  end
end
