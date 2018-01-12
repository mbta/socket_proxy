defmodule SocketProxy.Forwarder do
  use GenServer
  require Logger

  def start_link({ip, host}) do
    GenServer.start_link(__MODULE__, {ip, host})
  end

  def init({ip, host}) do
    send self(), :connect
    {:ok, %{ip: ip, host: host, socket: nil}}
  end

  def handle_info(:connect, state) do
    case :gen_tcp.connect(state.ip, state.host, [:binary, active: false, send_timeout: 5_000], 3_000) do
      {:ok, socket} ->
        Logger.info("Connected to socket #{Util.format_socket(socket)}")
        {:noreply, %{state | socket: socket}}
      {:error, _reason} ->
        send self(), :connect
        {:noreply, state}
    end
  end
  def handle_info({:data, _data}, %{socket: nil} = state) do
    {:noreply, state}
  end
  def handle_info({:data, data}, state) do
    case :gen_tcp.send(state.socket, data) do
      :ok ->
        {:noreply, state}
      {:error, reason} ->
        Logger.error("Sending socket error #{inspect(reason)} on #{Util.format_socket(state.socket)}. Reconnecting...")
        :gen_tcp.close(state.socket)
        send self(), :connect
        {:noreply, %{state | socket: nil}}
    end
  end
  def handle_info(msg, state) do
    Logger.error("Unknown message to sender: #{inspect(msg)}")
    {:noreply, state}
  end
end
