defmodule SocketProxy.Dispatcher do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(SocketProxy.Dispatcher, args, name: __MODULE__)
  end

  def init(_) do
    Logger.info("starting SocketProxy.Dispatcher")
    {:ok, []}
  end

  def new_data(pid \\ __MODULE__, data) do
    GenServer.call(pid, {:new_data, data})
  end

  def register(pid \\ __MODULE__, socket) do
    GenServer.call(pid, {:register, socket})
  end

  def handle_call({:new_data, data}, _from, sockets) do
    Enum.each(sockets, fn socket ->
      send socket, {:new_data, data}
    end)
    {:reply, :ok, sockets}
  end

  def handle_call({:register, socket}, _from, sockets) do
    Logger.info("Registering socket #{inspect(socket)}")
    {:reply, :ok, [socket | sockets]}
  end
end
