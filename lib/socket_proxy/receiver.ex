defmodule SocketProxy.Receiver do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({socket, destinations}) do
    destination_pids = Enum.map(destinations, fn {host, port} ->
      {:ok, pid} = SocketProxy.Forwarder.start_link({host, port})
      pid
    end)

    {:ok, {socket, destination_pids}}
  end

  def handle_info({:tcp, _port, data}, {socket, destination_pids} = state) do
    :inet.setopts(socket, active: :once)
    Enum.each(destination_pids, & send(&1, {:data, data}))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, {socket, _} = state) do
    Logger.warn("SocketProxy.Receiver tcp_closed for socket #{Util.format_socket(socket)}")
    {:stop, :tcp_socket_closed, state}
  end

  def handle_info(msg, state) do
    Logger.info("SocketProxy.Receiver unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
