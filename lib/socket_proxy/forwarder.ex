defmodule SocketProxy.Forwarder do
  use GenServer
  require Logger

  def start_link({host, port}) do
    GenServer.start_link(__MODULE__, {host, port})
  end

  def init({host, port}) do
    send(self(), :connect)
    {:ok, %{host: host, port: port, socket: nil}}
  end

  def handle_info(:connect, state) do
    case :gen_tcp.connect(
           state.host,
           state.port,
           [:binary, active: true, send_timeout: 5_000],
           3_000
         ) do
      {:ok, socket} ->
        Logger.info(
          "SocketProxy.Forwarder connected to socket=#{Util.format_socket(socket)} port=#{
            inspect(socket)
          } pid=#{inspect(self())}"
        )

        {:noreply, %{state | socket: socket}}

      {:error, _reason} ->
        Logger.warn("SocketProxy.Forwarder can't connect to #{inspect({state.host, state.port})}")
        Process.send_after(self(), :connect, 3_000)
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
        Logger.error(
          "SocketProxy.Forwarder send/2 error #{inspect(reason)} on socket=#{
            Util.format_socket(state.socket)
          } port=#{inspect(state.socket)} pid=#{inspect(self())}. Reconnecting..."
        )

        :gen_tcp.close(state.socket)
        send(self(), :connect)
        {:noreply, %{state | socket: nil}}
    end
  end

  def handle_info({:tcp, _port, data}, state) do
    Logger.info("SocketProxy.Forwarder received TCP data: #{inspect(data)}")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.warn(
      "SocketProxy.Forwarder socket closed. port=#{inspect(state.socket)} pid=#{inspect(self())} Reconnecting..."
    )

    send(self(), :connect)
    {:noreply, %{state | socket: nil}}
  end

  def handle_info(:receiver_closed, state) do
    Logger.info("SocketProxy.Forwarder receiver closed. Terminating...")
    :gen_tcp.close(state.socket)
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.error("Unknown message to sender: #{inspect(msg)}")
    {:noreply, state}
  end
end
