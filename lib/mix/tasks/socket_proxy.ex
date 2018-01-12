defmodule Mix.Tasks.SocketProxy do
  use Mix.Task
  require Logger

  @doc """
  Usage: mix socket_proxy --listen-port 8080 123.123.123.123:8080 12.12.12.12:9999
  """
  def run(args) do
    {opts, ips, []} = OptionParser.parse(args, switches: [listen_port: :integer])
    destinations = Enum.map(ips, &parse_ip_port/1)

    {:ok, _pid} = Supervisor.start_link([
      {SocketProxy, {opts[:listen_port], destinations}}
    ], strategy: :one_for_one)
    
    Process.sleep(:infinity)
  end

  defp parse_ip_port(ip_port) do
    [raw_host, raw_port] = String.split(ip_port, ":")
    port = String.to_integer(raw_port)
    {:ok, host} = raw_host |> String.to_charlist |> :inet.parse_address
    {host, port}
  end
end
