defmodule Mix.Tasks.FakeSource do
  use Mix.Task
  require Logger

  @doc """
  Ex: mix fake_source --port 8080
  """
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [port: :integer])
    port = opts[:port]
    host = {127, 0, 0, 1}
    {:ok, sock} = do_connect(host, port)
    do_send(sock)
  end

  def do_connect(host, port) do
    case :gen_tcp.connect(host, port, [:binary, active: false]) do
      {:ok, sock} -> {:ok, sock}
      {:error, err} ->
        Logger.info("Couldn't connect: #{err}, trying again shortly")
        :timer.sleep(2_000)
        do_connect(host, port)
    end
  end

  def do_send(sock) do
    data = :crypto.strong_rand_bytes(5)
    Logger.info("Sending #{inspect(data)}")
    :gen_tcp.send(sock, data)
    :timer.sleep(1_000)
    do_send(sock)
  end
end
