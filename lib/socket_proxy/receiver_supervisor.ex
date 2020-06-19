defmodule SocketProxy.ReceiverSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_child(arg) do
    spec = %{id: SocketProxy.Receiver, start: {SocketProxy.Receiver, :start_link, [arg]}, restart: :temporary}
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl DynamicSupervisor
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
