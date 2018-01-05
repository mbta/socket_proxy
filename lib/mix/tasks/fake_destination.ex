defmodule Mix.Tasks.FakeDestination do
  use Mix.Task
  require Logger

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [port: :integer])
    port = opts[:port]

    {:ok, lsock} = :gen_tcp.listen(port, [:binary, active: false])
    Logger.info("Listening on port #{port}")
    {:ok, sock} = :gen_tcp.accept(lsock)
    do_receive(sock)
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
