defmodule SocketProxy.Listener do
  defmodule State do
    defstruct [:listen_socket, :socket, :port, :dispatcher_fn]
  end

  use GenServer
  require Logger

  @doc """
  args should be a keyword list with :port and :dispatcher.
  :dispatcher should be the name of a module that has a
  new_data/1 function that returns :ok.
  """
  def start_link(args) do
    GenServer.start_link(SocketProxy.Listener, args)
  end

  def init(args) do
    dispatcher_fn = Keyword.fetch!(args, :dispatcher_fn)
    port = Keyword.fetch!(args, :port)

    Logger.info("Starting SocketProxy.Listener on port #{port}")
    {:ok, lsock} = :gen_tcp.listen(port, [:binary, active: :once, packet: :raw, backlog: 0])
    schedule_accept()
    {:ok, %State{listen_socket: lsock, port: port, dispatcher_fn: dispatcher_fn}}
  end

  def handle_info(:try_accept, %State{listen_socket: listen_socket, port: port, socket: nil} = state) do
    Logger.info("Trying to accept connection from source socket...")
    case :gen_tcp.accept(listen_socket, 1_000) do
      {:ok, socket} ->
        Logger.info("Socket accepted.")
        {:noreply, %{state | socket: socket}}
      {:error, :timeout} ->
        Logger.warn("No source socket. Will try again.")
        schedule_accept()
        {:noreply, state}
      {:error, :closed} ->
        Logger.error("ListenSocket was closed. Will try to reopen.")
        {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, active: :once, backlog: 1])
        schedule_accept()
        {:noreply, %{state | listen_socket: listen_socket}}
      err ->
        Logger.error("Unknown socket accept error: #{inspect(err)}. Stopping")
        {:stop, :unknown_socket_error, state}
    end
  end
  def handle_info(:try_accept, %State{socket: socket} = state) when not is_nil(socket) do
    {:noreply, state}
  end

  def handle_info({:tcp, _port, data}, %{socket: socket, dispatcher_fn: dispatcher_fn} = state) do
    :inet.setopts(socket, active: :once)
    :ok = dispatcher_fn.(data)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    schedule_accept()
    {:noreply, %{state | socket: nil}}
  end

  def handle_info(msg, state) do
    Logger.info("Unknown msg: #{inspect(msg)}")
    {:noreply, state}
  end

  defp schedule_accept do
    Process.send_after(self(), :try_accept, 3_000)
  end
end
