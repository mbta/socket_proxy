defmodule SocketProxy.ListenerTest do
  use ExUnit.Case
  alias SocketProxy.Listener

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    dispatcher_fn = fn data -> Agent.update(agent, fn state -> [data | state] end) end
    agent_state_fn = fn -> Agent.get(agent, & &1) end
    %{dispatcher: dispatcher_fn, agent_state: agent_state_fn}
  end

  test "when started before source, will wait for connection", fns do
    {:ok, _pid} = Listener.start_link(port: 7000, dispatcher_fn: fns[:dispatcher])
    :timer.sleep(4_000)
    {:ok, sock} = :gen_tcp.connect({127, 0, 0, 1}, 7000, [:binary, active: false])
    :ok = :gen_tcp.send(sock, "message")
    :timer.sleep(100)
    assert fns[:agent_state].() == ["message"]
    :gen_tcp.close(sock)
  end

  test "when source connection closed, will wait for a new connection", fns do
    {:ok, _pid} = Listener.start_link(port: 7000, dispatcher_fn: fns[:dispatcher])
    {:ok, sock} = :gen_tcp.connect({127, 0, 0, 1}, 7000, [:binary, active: false])
    :ok = :gen_tcp.send(sock, "message")
    :gen_tcp.close(sock)
    {:ok, sock2} = :gen_tcp.connect({127, 0, 0, 1}, 7000, [:binary, active: false])
    :ok = :gen_tcp.send(sock2, "message2")
    :timer.sleep(7_000)
    assert fns[:agent_state].() == ["message2", "message"]
    :gen_tcp.close(sock2)
  end
end
