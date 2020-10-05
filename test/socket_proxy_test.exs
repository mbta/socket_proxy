defmodule SocketProxyTest do
  use ExUnit.Case

  test "the whole system works" do
    # Start up sources and destinations
    {:ok, src1} = GenServer.start_link(FakeSource, 8080)
    {:ok, src2} = GenServer.start_link(FakeSource, 8080)
    {:ok, dest1} = GenServer.start_link(FakeDestination, 8081)
    {:ok, dest2} = GenServer.start_link(FakeDestination, 8082)
    # Start up socket proxy
    port = 8080
    destinations = [{'127.0.0.1', 8081}, {'localhost', 8082}]
    Application.put_env(:socket_proxy, :listen_port, port)
    Application.put_env(:socket_proxy, :destinations, destinations)
    {:ok, _pid} = SocketProxy.Application.start_listener()
    :timer.sleep(50)

    #  Send some messages
    GenServer.call(src1, {:send_message, "src1msg1"})
    GenServer.call(src1, {:send_message, "src1msg2"})
    :timer.sleep(10)
    GenServer.call(src2, {:send_message, "src2msg1"})
    GenServer.call(src2, {:send_message, "src2msg2"})
    :timer.sleep(10)

    # Assert those messages were received
    assert GenServer.call(dest1, :messages) == "src1msg1src1msg2src2msg1src2msg2"
    assert GenServer.call(dest2, :messages) == "src1msg1src1msg2src2msg1src2msg2"

    # Source dies
    Process.flag :trap_exit, true
    Process.exit(src1, :shutdown)
    :timer.sleep(3_500)

    # A new source starts
    {:ok, new_src} = GenServer.start_link(FakeSource, 8080)

    # New source's messages arrive at destinations
    GenServer.call(new_src, {:send_message, "newmsg"})
    :timer.sleep(10)
    assert GenServer.call(dest1, :messages) =~ "newmsg"
    assert GenServer.call(dest2, :messages) =~ "newmsg"

    # Destination dies and restarts
    :ok = GenServer.stop(dest1, :normal, 100)
    {:ok, new_dest} = GenServer.start_link(FakeDestination, 8081)
    :timer.sleep(3_500) # Socket Proxy tries to reconnect every 3_000

    # New destination receives new messages
    GenServer.call(new_src, {:send_message, "still_alive?"})
    :timer.sleep(10)
    assert GenServer.call(new_dest, :messages) == "still_alive?"
  end
end

defmodule FakeDestination do
  use GenServer

  def init(port) do
    {:ok, lsock} = :gen_tcp.listen(port, [:binary, active: true, reuseaddr: true])
    GenServer.cast(self(), :accept)
    {:ok, {lsock, [], ""}}
  end

  def handle_cast(:accept, {lsock, socks, messages} = state) do
    case :gen_tcp.accept(lsock, 10) do
      {:ok, sock} ->
        GenServer.cast(self(), :accept)
        {:noreply, {lsock, [sock | socks], messages}}
      {:error, :timeout} ->
        GenServer.cast(self(), :accept)
        {:noreply, state}
    end
  end

  def handle_call(:messages, _from, {_, _, msgs} = state), do: {:reply, msgs, state}

  def handle_info({:tcp, _port, data}, {lsock, socks, msgs}) do
    {:noreply, {lsock, socks, msgs <> data}}
  end

  def handle_info({:tcp_closed, _}, state) do
    {:noreply, state}
  end

  def terminate(_reason, {lsock, socks, _msgs}) do
    :gen_tcp.close(lsock)
    Enum.each(socks, & :gen_tcp.close(&1))
  end
end

defmodule FakeSource do
  use GenServer

  def init(port) do
    GenServer.cast(self(), {:connect, port})
    {:ok, nil}
  end

  def handle_cast({:connect, port}, _state) do
    {:ok, socket} = connect(port)
    {:noreply, socket}
  end

  def handle_call({:send_message, data}, _from, socket) do
    :ok = :gen_tcp.send(socket, data)
    {:reply, :ok, socket}
  end

  defp connect(port) do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: true, reuseaddr: true]) do
      {:ok, socket} -> {:ok, socket}
      _ ->
        :timer.sleep(10)
        connect(port)
    end
  end
end
