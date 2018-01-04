defmodule SocketProxy.ListenerTest do
  use ExUnit.Case
  alias SocketProxy.Listener

  test "when started before source, will wait for connection" do
    # server = Agent.start_link(fn -> [] end)
    # dispatcher_fn = fn data -> Agent.update(server, fn state -> [data | state] end) end
    # {:ok, pid} = Listener.start_link(port: 7000, dispatcher_fn: dispatcher_fn)
    # :timer.sleep(4_000)
    # {:ok, sock} = :gen_tcp.connect({127, 0, 0, 1}, 7000, [:binary, active: false])
    # :ok = :gen_tcp.send(sock, "message")
    # assert Agent.get(server, & &1) == ["message"]
  end
end
