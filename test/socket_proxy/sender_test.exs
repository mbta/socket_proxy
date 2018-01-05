defmodule SocketProxy.SenderTest do
  use ExUnit.Case
  alias SocketProxy.Sender

  test "will eventually connect if started before server online" do
    dispatcher_fn = fn pid -> pid end
    {:ok, sender} = Sender.start_link(ip_port: "127.0.0.1:9000", dispatcher_fn: dispatcher_fn)
    :timer.sleep(4_000)

    {:ok, lsock} = :gen_tcp.listen(9000, [:binary, active: false, reuseaddr: true])
    {:ok, sock} = :gen_tcp.accept(lsock, 5_000)

    send sender, {:new_data, "msg1"}
    send sender, {:new_data, "msg2"}
    :timer.sleep(300)

    assert :gen_tcp.recv(sock, 0) == {:ok, "msg1msg2"}
  end

  test "handles a reconnection to server, sends buffered data" do
    dispatcher_fn = fn pid -> pid end
    {:ok, sender} = Sender.start_link(ip_port: "127.0.0.1:9001", dispatcher_fn: dispatcher_fn)

    {:ok, lsock} = :gen_tcp.listen(9001, [:binary, active: false, reuseaddr: true])
    {:ok, sock} = :gen_tcp.accept(lsock, 5_000)

    send sender, {:new_data, "msg1"}
    :timer.sleep(300)

    assert :gen_tcp.recv(sock, 0) == {:ok, "msg1"}

    :ok = :gen_tcp.close(sock)
    :ok = :gen_tcp.close(lsock)

    send sender, {:new_data, "msg2"}
    send sender, {:new_data, "msg3"}
    :timer.sleep(1_000) # it will try to send data and be unable to
    {:ok, lsock2} = :gen_tcp.listen(9001, [:binary, active: false, reuseaddr: true])
    {:ok, sock2} = :gen_tcp.accept(lsock2, 5_000)
    :timer.sleep(300)

    assert :gen_tcp.recv(sock2, 0) == {:ok, "msg2msg3"}
  end
end
