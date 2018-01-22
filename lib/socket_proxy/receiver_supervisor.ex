defmodule SocketProxy.ReceiverSupervisor do
  use Supervisor
  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([receiver_child_spec()], strategy: :simple_one_for_one)
  end

  def start_child(arg) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [arg])
  end

  def receiver_child_spec do
    Supervisor.child_spec(SocketProxy.Receiver, start: {SocketProxy.Receiver, :start_link, []})
  end
end
