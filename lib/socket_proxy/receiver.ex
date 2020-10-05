defmodule SocketProxy.Receiver do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  defstruct socket: nil, destination_pids: []

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {ref, transport, opts[:destinations]})
  end

  @impl GenServer
  def init({ref, transport, destinations}) do
    {:ok, %__MODULE__{}, {:continue, {ref, transport, destinations}}}
  end

  @impl GenServer
  def handle_continue({ref, transport, destinations}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)

    destination_pids =
      Enum.map(destinations, fn {host, port} ->
        {:ok, pid} = SocketProxy.Forwarder.start_link({host, port})
        pid
      end)

    Logger.info("Accepted socket: #{Util.format_socket(socket)}")

    {:noreply, %{state | socket: socket, destination_pids: destination_pids}}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, destination_pids: destination_pids} = state
      ) do
    Enum.each(destination_pids, &send(&1, {:data, data}))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    Logger.warn("SocketProxy.Receiver tcp_closed for socket #{Util.format_socket(socket)}")

    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info("SocketProxy.Receiver unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
