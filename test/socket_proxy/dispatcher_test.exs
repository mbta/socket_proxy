defmodule SocketProxy.DispatcherTest do
  use ExUnit.Case
  alias SocketProxy.Dispatcher

  test "sends message to all alive processes, even if one dies" do
    test_pid = self()

    pid1 = spawn fn ->
      receive do
        {:new_data, data} -> send test_pid, {:got_data_1, data}
      end
    end

    pid2 = spawn fn ->
      receive do
        {:new_data, data} -> send test_pid, {:got_data_2, data}
      end
    end

    pid3 = spawn fn ->
      receive do
        {:new_data, data} -> send test_pid, {:got_data_3, data}
      end
    end

    {:ok, dispatcher} = Dispatcher.start_link([])
    Dispatcher.register(dispatcher, pid1)
    Dispatcher.register(dispatcher, pid2)
    Dispatcher.register(dispatcher, pid3)

    Process.exit(pid3, :kill)
    :timer.sleep(100)

    Dispatcher.new_data(dispatcher, "here it is")

    assert_receive({:got_data_1, "here it is"})
    assert_receive({:got_data_2, "here it is"})
  end
end
