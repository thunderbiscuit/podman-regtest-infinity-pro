# Readme

The _Podman Regtest Infinity Pro_ allows you to create a robust regtest environment which you can turn on and off at will using Podman. The final environment includes a lot of useful tools, namely:

1. A bitcoin core node and daemon (serving compact block filters)
2. bitcoin-cli enabled
3. An Electrum server
4. An Esplora server
5. A block explorer
6. Useful just commands for working with the daemon from your command line

## Get Started

To get started with the _Podman Regtest Infinity Pro_, check out:

- [The website](https://regtestinfinitypro.dev/)
- [The docs](https://thunderbiscuit.github.io/podman-regtest-infinity-pro/)
- [The original companion blog post](https://thunderbiscuit.com/posts/podman-bitcoin/)
- [The YouTube overview and demo](https://www.youtube.com/watch?v=zofo5k9Cwcg)

## Usage Overview

Use the [`just`](https://github.com/casey/just) tool and leverage the commands defined in the `justfile`.

```shell
just mine 21
just sendto <address>
just bitcoindlogs
just esploralogs
```

## Building, Starting, and Stopping the Pod

```shell
# Clone the repo, say in ~/podman/
cd ~/podman/
git clone https://github.com/thunderbiscuit/podman-regtest-infinity-pro.git

# Build the container
cd ~/podman/podman-regtest-infinity-pro/
podman machine start regtest

# Set BITCOIN_VERSION and TARGET_ARCH to use the bitcoin core versions you need using the --build-arg argument on the podman command.
# Examples for BITCOIN_VERSION:
#    - 29.0
#    - 28.1
#    - 27.0
# Examples for TARGET_ARCH (see https://bitcoincore.org/bin/bitcoin-core-28.0/ for all available versions):
#    - aarch64-linux-gnu
#    - arm64-apple-darwin
#    - x86_64-apple-darwin
#    - win64
#    - x86_64-linux-gnu

podman --connection regtest build --build-arg BITCOIN_VERSION=28.1 --build-arg TARGET_ARCH=x86_64-linux-gnu --tag localhost/regtest:v0.1.0 --file ./Containerfile
podman --connection regtest create --name RegtestInfinityPro --publish 18443:18443 --publish 18444:18444 --publish 3002:3002 --publish 3003:3003 --publish 60401:60401 localhost/regtest:v0.1.0

# Using the container
# Start the machine + pod
just start
# List all available just commands
just
# Mine 4 blocks
just mine 4
# Execute bitcoin-cli command directly in pod
just cli getnetworkinfo
# Launch block explorer
just explorer
# Stop the container and the machine
just stop
```
