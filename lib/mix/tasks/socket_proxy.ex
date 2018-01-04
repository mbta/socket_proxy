defmodule Mix.Tasks.SocketProxy do
  use Mix.Task
  require Logger

  @doc """
  Usage: mix socket_proxy --listen-port 8080 123.123.123.123:8080 12.12.12.12:9999
  """
  def run(args) do
    {opts, ips, []} = OptionParser.parse(args, switches: [listen_port: :integer])
    Application.put_env(:socket_proxy, :listen_port, opts[:listen_port])
    Application.put_env(:socket_proxy, :destinations, ips)
    {:ok, [:socket_proxy]} = Application.ensure_all_started(:socket_proxy)
    Process.sleep(:infinity)
  end
end
