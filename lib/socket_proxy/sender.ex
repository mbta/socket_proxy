defmodule SocketProxy.Sender do
  defmodule State do
    defstruct [:host, :port, :buffer, :socket]
  end

  use GenServer
  require Logger

  @max_buffer 500

  def start_link(ip_port) do
    GenServer.start_link(SocketProxy.Sender, ip_port)
  end

  def init(ip_port) do
    {host, port} = parse_ip_port(ip_port)
    Logger.info("Starting SocketProxy.Sender with host #{inspect(host)} and port #{port}")
    SocketProxy.Dispatcher.register(self())
    schedule_connect(200)
    {:ok, %State{host: host, port: port, buffer: []}}
  end

  def handle_info(:try_connect, %{host: host, port: port} = state) do
    Logger.info("SocketProxy.Sender trying to connect to #{inspect(host)}:#{port}")
    case :gen_tcp.connect(host, port, [active: false, packet: :raw, send_timeout: 5_000], 1_000) do
      {:ok, socket} ->
        Logger.info("Connected to #{inspect(host)}:#{port}")
        schedule_send(1000)
        {:noreply, %{state | socket: socket }}
      {:error, reason} ->
        Logger.warn("Could not connect to destination #{inspect(host)}:#{port} because: #{inspect(reason)}. Will try again.")
        schedule_connect(3_000)
        {:noreply, state}
    end
  end

  def handle_info({:new_data, data}, %{buffer: buffer} = state) do
    {:noreply, %{state | buffer: Enum.take([data | buffer], @max_buffer)}}
  end

  def handle_info(:send_data, %{socket: nil} = state) do
    {:noreply, state}
  end
  def handle_info(:send_data, %{buffer: []} = state) do
    schedule_send(200)
    {:noreply, state}
  end
  def handle_info(:send_data, %{buffer: buffer, socket: socket} = state) do
    case :gen_tcp.send(socket, Enum.reverse(buffer)) do
      :ok ->
        schedule_send(200)
        {:noreply, %{state | buffer: []}}
      {:error, err} ->
        Logger.error("Send error: #{inspect(err)}")
        :gen_tcp.close(socket)
        schedule_connect(1_000)
        {:noreply, %{state | socket: nil}}
    end
  end

  defp parse_ip_port(ip_port) do
    [raw_host, raw_port] = String.split(ip_port, ":")
    port = String.to_integer(raw_port)
    {:ok, host} = raw_host |> String.to_charlist |> :inet.parse_address
    {host, port}
  end

  defp schedule_send(ms) do
    Process.send_after(self(), :send_data, ms)
  end

  defp schedule_connect(ms) do
    Process.send_after(self(), :try_connect, ms)
  end
end
