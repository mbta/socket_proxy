defmodule SocketProxy.Receiver do
  use GenServer, restart: :temporary, shutdown: :brutal_kill
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({socket, destinations}) do
    GenServer.cast(self(), {:proxy, socket, destinations})
    {:ok, []}
  end

  def handle_cast({:proxy, socket, destinations}, _state) do
    proxy(socket, destinations)
    {:stop, :proxy_dead, []}
  end

  def proxy(sock, destinations) do
    destination_pids = Enum.map(destinations, fn {ip, host} ->
      {:ok, pid} = SocketProxy.Forwarder.start_link({ip, host})
      pid
    end)

    recv(sock, destination_pids)
  end

  def recv(sock, destination_pids) do
    case :gen_tcp.recv(sock, 0, 60_000) do
      {:ok, data} ->
        Enum.each(destination_pids, fn pid ->
          send pid, {:data, data}
        end)
        recv(sock, destination_pids)
      {:error, err} ->
        Logger.warn("Socket read error #{inspect(err)} for socket #{Util.format_socket(sock)}")
        exit(:not_receiving_data) # linked sender processes will terminate as well
    end
  end
end
