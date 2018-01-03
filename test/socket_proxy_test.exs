defmodule SocketProxyTest do
  use ExUnit.Case
  doctest SocketProxy

  test "greets the world" do
    assert SocketProxy.hello() == :world
  end
end
