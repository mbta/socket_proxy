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
    do_send(sock, host, port)
  end

  def do_connect(host, port) do
    case :gen_tcp.connect(host, port, [:binary, active: false, send_timeout: 1000]) do
      {:ok, sock} -> {:ok, sock}
      {:error, err} ->
        Logger.info("Couldn't connect: #{err}, trying again shortly")
        :timer.sleep(2_000)
        do_connect(host, port)
    end
  end

  def do_send(sock, host, port) do
    data = :crypto.strong_rand_bytes(5)
    Logger.info("Sending #{inspect(data)}")
    case :gen_tcp.send(sock, data) do
      :ok ->
        :timer.sleep(1_000)
        do_send(sock, host, port)
      {:error, err} ->
        Logger.error("Err: #{inspect(err)}")
        :gen_tcp.close(sock)
        do_connect(host, port)
    end
  end
end
