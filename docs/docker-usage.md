# Using Pre-built Docker Images

This guide shows how to use the pre-built images for local development and testing.

## Quick Start

```bash
# Pull the image
docker pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0

# Create the container
docker create --name RegtestInfinityPro \
  --publish 0.0.0.0:18443:18443 \
  --publish 0.0.0.0:18444:18444 \
  --publish 0.0.0.0:3002:3002 \
  --publish 0.0.0.0:3003:3003 \
  --publish 0.0.0.0:60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0

# Start the container
docker start RegtestInfinityPro

# Wait ~15 seconds for services to start
sleep 15
```

Publishing the ports on `0.0.0.0` makes the services reachable from other devices on your local network, which is handy for testing mobile apps on real hardware. To restrict a port to your own machine instead, publish it on the loopback interface, e.g. `--publish 127.0.0.1:18443:18443` — a sensible hardening for the RPC port, which uses well-known credentials.

## Manual Commands

The repository's `justfile` is built around a Podman machine setup, so with Docker you interact with the container directly. Here are the common commands:

### Mining Blocks

```bash
# Get the authentication cookie
COOKIE=$(docker exec RegtestInfinityPro cat /root/.bitcoin/regtest/.cookie | cut -d ':' -f2)

# Mine 1 block
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -generate 1

# Mine 10 blocks
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -generate 10
```

### Running bitcoin-cli Commands

```bash
COOKIE=$(docker exec RegtestInfinityPro cat /root/.bitcoin/regtest/.cookie | cut -d ':' -f2)

# Get blockchain info
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  getblockchaininfo

# Get network info
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  getnetworkinfo
```

### Creating and Using a Wallet

```bash
COOKIE=$(docker exec RegtestInfinityPro cat /root/.bitcoin/regtest/.cookie | cut -d ':' -f2)

# Create wallet
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  createwallet mywallet

# Get new address
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -rpcwallet=mywallet \
  getnewaddress

# Check balance
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -rpcwallet=mywallet \
  getbalance
```

### Viewing Logs

```bash
# All container output
docker logs RegtestInfinityPro

# Bitcoin Core logs (follow)
docker exec -it RegtestInfinityPro tail -f /root/log/bitcoin.log

# Esplora logs (follow)
docker exec -it RegtestInfinityPro tail -f /root/log/esplora.log

# Block explorer logs (follow)
docker exec -it RegtestInfinityPro tail -f /root/log/fbbe.log
```

### Accessing Services

| Service | URL | Description |
|---------|-----|-------------|
| Bitcoin RPC | http://localhost:18443 | JSON-RPC interface |
| Esplora | http://localhost:3002 | REST API for blockchain data |
| Block Explorer | http://localhost:3003 | Web UI |
| Electrum | tcp://localhost:60401 | Electrum protocol server |

## Container Management

### Starting and Stopping

```bash
# Start
docker start RegtestInfinityPro

# Stop
docker stop RegtestInfinityPro

# Restart (fresh blockchain)
docker stop RegtestInfinityPro
docker rm RegtestInfinityPro
docker create --name RegtestInfinityPro \
  --publish 0.0.0.0:18443:18443 \
  --publish 0.0.0.0:18444:18444 \
  --publish 0.0.0.0:3002:3002 \
  --publish 0.0.0.0:3003:3003 \
  --publish 0.0.0.0:60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
docker start RegtestInfinityPro
```

### Persistent Data

Blockchain data lives in the container's filesystem, so it survives `docker stop` / `docker start` cycles but is lost when the container is removed. To keep blockchain data across container removal and recreation, use a volume:

```bash
# Create a volume
docker volume create bitcoin-regtest-data

# Create container with volume
docker create --name RegtestInfinityPro \
  --publish 0.0.0.0:18443:18443 \
  --publish 0.0.0.0:18444:18444 \
  --publish 0.0.0.0:3002:3002 \
  --publish 0.0.0.0:3003:3003 \
  --publish 0.0.0.0:60401:60401 \
  --volume bitcoin-regtest-data:/root/.bitcoin \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
```

## Troubleshooting

### Services Not Ready

Wait 15-20 seconds after starting the container for all services to initialize:

```bash
docker start RegtestInfinityPro
sleep 15

# Test if services are ready
curl http://localhost:3002/blocks/tip/height
```

### Port Already in Use

If ports are already bound:

```bash
# Find what's using the port
lsof -i :18443

# Use different host ports
docker create --name RegtestInfinityPro \
  --publish 0.0.0.0:28443:18443 \
  --publish 0.0.0.0:28444:18444 \
  --publish 0.0.0.0:13002:3002 \
  --publish 0.0.0.0:13003:3003 \
  --publish 0.0.0.0:50401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
```

### Container Won't Start

Check logs for errors:

```bash
docker logs RegtestInfinityPro
```

## Using with Podman

The image works with Podman too - just replace `docker` with `podman`:

```bash
podman pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
podman create --name RegtestInfinityPro \
  --publish 0.0.0.0:18443:18443 \
  --publish 0.0.0.0:18444:18444 \
  --publish 0.0.0.0:3002:3002 \
  --publish 0.0.0.0:3003:3003 \
  --publish 0.0.0.0:60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
podman start RegtestInfinityPro
```
