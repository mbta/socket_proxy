# SocketProxy

A simple app that listens on a port and proxies (and possibly fans out) data to multiple given destinations. Each incoming connection is fanned out independently to all the destinations. For example, 2 sources and 2 destinations results in 6 sockets: 2 incoming, and 4 outgoing (2 to each).

## Usage

```
$ env SOCKET_PROXY_LISTEN_PORT=8001 SOCKET_PROXY_DESTINATIONS="12.12.12.12:8002, 13.13.13.13:8003" mix run --no-halt
```

## Testing

This app comes with a fake sources which generate random strings and fake servers which can serve as the destinations. Here's how to set them up.

Open several terminal windows, all in the socket_proxy directory.

Start up a couple servers on different ports:

```
$ mix fake_destination --port 8080  # in one window
$ mix fake_destination --port 8081  # in another window
```

In more terminal windows, start up the sources which will attempt to connect to a port and then start sending random bytes once the connection is made.

```
$ mix fake_source --port 8000
$ mix fake_source --port 8000
```

You can then run socket proxy to connect them all:

```
$ env SOCKET_PROXY_LISTEN_PORT=8000 SOCKET_PROXY_DESTINATIONS="127.0.0.1:8080, 127.0.0.1:8081" mix run --no-halt
```

Observe that data being generated by the two fake sources appear in both the fake servers. Try killing and restarting any combination of the windows and see that the data continues to flow.

## Architecture

This is an OTP application that starts two children: the main `SocketProxy` GenServer and a `SocketProxy.ReceiverSupervisor` `:simple_one_for_one` Dynamic Supervisor.

The `SocketProxy` GenServer listens on a port and operates a `gen_tcp` accept loop. In order to be a good OTP citizen, it manages the accept loop by calling `:gen.tcp.accept/2` with a timeout, and then casting itself a message to try again. That way, other messages (e.g. from its Supervisor) have a chance to be processed.

When `SocketProxy` does accept a connection, it starts a `SocketProxy.Receiver` child under the `SocketProxy.ReceiverSupervisor`. This process in turn spawns *and links* a `SocketProxy.Forwarder` GenServer for each of its destinations. Incoming data is handled by the `Receiver` process, and fanned out to each destination by sending a `{:data, data}` message.

Because the `Receiver` is linked to the `Forwarder`s, if any of them crash or exit, *all* of them do. This is to help manage cleanup should the Receiver fail (incoming data socket is broken). If that happens, it and all the Forwarder processes exit, and the source should re-connect to socket_proxy, which will accept it from its running accept loop, and spawn a new Receiver, which spawns new linked Forwarders, and so on.
