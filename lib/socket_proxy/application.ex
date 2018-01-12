defmodule SocketProxy.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting SocketProxy.Application")

    children = []
    opts = [strategy: :one_for_all, name: SocketProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
