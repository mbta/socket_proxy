#!/usr/bin/env bash
set -e

# Run this from the repo root directory (i.e. /c/Users/RTRUser/GitHub/socket_proxy_release_prod)
# Takes the release node name as an argument (e.g. `$ ./build_release.sh socket_proxy`)

if [ $# -eq 0 ]; then
  echo "No argument provided"
  exit 1
fi

ERL_DIR="erl10.7" # erlang/otp 22.3
ELIXIR_DIR="elixir1.10.3"

rm -rf _build-prev
test -e "_build" && mv _build _build-prev

env MIX_ENV=prod PATH="/c/Users/RTRUser/bin/$ERL_DIR/bin/:/c/Users/RTRUser/bin/$ELIXIR_DIR/bin/:$PATH" mix local.hex --force
env MIX_ENV=prod PATH="/c/Users/RTRUser/bin/$ERL_DIR/bin/:/c/Users/RTRUser/bin/$ELIXIR_DIR/bin/:$PATH" mix local.rebar --force
env MIX_ENV=prod PATH="/c/Users/RTRUser/bin/$ERL_DIR/bin/:/c/Users/RTRUser/bin/$ELIXIR_DIR/bin/:$PATH" mix deps.get
env MIX_ENV=prod PATH="/c/Users/RTRUser/bin/$ERL_DIR/bin/:/c/Users/RTRUser/bin/$ELIXIR_DIR/bin/:$PATH" RELEASE_NODE=$1 mix release

echo "Release is built. Restart the Windows service to run it."
