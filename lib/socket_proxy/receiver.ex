defmodule SocketProxy.Receiver do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  @staleness_check_interval_ms Application.compile_env(
                                 :socket_proxy,
                                 :staleness_check_interval_ms
                               )

  defstruct socket: nil, destination_pids: [], port: nil, received: 0

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {ref, transport, opts[:destinations], opts[:port]})
  end

  @impl GenServer
  def init({ref, transport, destinations, port}) do
    :timer.send_interval(@staleness_check_interval_ms, :staleness_check)

    {:ok, %__MODULE__{}, {:continue, {ref, transport, destinations, port}}}
  end

  @impl GenServer
  def handle_continue({ref, transport, destinations, port}, state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)

    destination_pids =
      Enum.map(destinations, fn {host, port} ->
        {:ok, pid} = SocketProxy.Forwarder.start_link({host, port})
        pid
      end)

    Logger.info("Accepted socket: #{Util.format_socket(socket)}")

    {:noreply, %{state | socket: socket, destination_pids: destination_pids, port: port}}
  end

  @impl GenServer
  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, destination_pids: destination_pids, received: received} = state
      ) do
    Enum.each(destination_pids, &send(&1, {:data, data}))
    {:noreply, %{state | received: received + 1}}
  end

  def handle_info(
        {:tcp_closed, _socket},
        %{port: port, destination_pids: destination_pids} = state
      ) do
    Logger.warn("#{__MODULE__} tcp_closed for socket listening on port #{port}")

    Enum.each(destination_pids, &send(&1, :receiver_closed))

    {:stop, :normal, state}
  end

  def handle_info(
        :staleness_check,
        %{destination_pids: destination_pids, received: 0} = state
      ) do
    Logger.warn("#{__MODULE__} received no messages, terminating pid=#{inspect(self())}")

    Enum.each(destination_pids, &send(&1, :receiver_closed))

    {:stop, :normal, state}
  end

  def handle_info(
        :staleness_check,
        %{received: received} = state
      ) do
    Logger.info("#{__MODULE__} pid=#{inspect(self())} received=#{received}")

    {:noreply, %{state | received: 0}}
  end

  def handle_info(msg, state) do
    Logger.info("#{__MODULE__} unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
