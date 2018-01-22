defmodule Mix.Tasks.FakeDestination do
  use Mix.Task
  require Logger

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [port: :integer])
    port = opts[:port]

    {:ok, lsock} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    Logger.info("Listening on port #{port}")
    do_accept(lsock)
  end

  defp do_accept(lsock) do
    {:ok, sock} = :gen_tcp.accept(lsock)
    spawn fn ->
      do_receive(sock)
    end
    do_accept(lsock)
  end

  defp do_receive(sock) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        Logger.info("Received: #{inspect(data)}")
        do_receive(sock)
      {:error, err} ->
        Logger.error("Error: #{inspect(err)}")
    end
  end
end
