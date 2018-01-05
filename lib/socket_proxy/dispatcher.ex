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

  def register(pid \\ __MODULE__, callback_pid) do
    GenServer.call(pid, {:register, callback_pid})
  end

  def handle_call({:new_data, data}, _from, callback_pids) do
    Enum.each(callback_pids, fn callback_pid ->
      send callback_pid, {:new_data, data}
    end)
    {:reply, :ok, callback_pids}
  end

  def handle_call({:register, callback_pid}, _from, callback_pids) do
    Logger.info("Registering callback_pid #{inspect(callback_pid)}")
    {:reply, :ok, [callback_pid | callback_pids]}
  end
end
