defmodule SocketProxy do
  @moduledoc """
  Supervised process that spends most of its time in a TCP accept
  loop. If the accept loop fails, its supervisor should restart it all.
  """

  use GenServer
  require Logger

  def start_link({port, destinations}) do
    GenServer.start_link(__MODULE__, {port, destinations})
  end

  def init({port, destinations}) do
    Logger.info("Initializing Listener")
    {:ok, lsock} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    Logger.info("Listening on port #{port}")
    GenServer.cast(self(), :accept)
    {:ok, %{lsock: lsock, destinations: destinations}}
  end

  def handle_cast(:accept, %{lsock: lsock, destinations: destinations} = state) do
    case :gen_tcp.accept(lsock, 3_000) do
      {:ok, sock} ->
        Logger.info("Accepted socket: #{Util.format_socket(sock)}")
        spawn fn -> SocketProxy.Receiver.proxy(sock, destinations) end
        GenServer.cast(self(), :accept)
        {:noreply, state}
      {:error, :timeout} ->
        GenServer.cast(self(), :accept)
        {:noreply, state}
      {:error, err} ->
        Logger.error("Socket listener died: #{inspect(err)}")
        :ok = :gen_tcp.close(lsock)
        {:stop, :loop_accept_dead, %{}}
    end
  end
end
