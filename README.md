# SocketProxy

A simple app that listens on a port and proxies (and possibly fans out) data to multiple given destinations.

## Usage

```
$ mix socket_proxy --listen-port 8001 12.12.12.12:8002 13.13.13.13:8003
```
