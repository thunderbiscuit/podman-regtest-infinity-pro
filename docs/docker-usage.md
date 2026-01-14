# Using Pre-built Docker Images

This guide shows how to use the pre-built images for local development and testing.

## Quick Start

```bash
# Pull the image
docker pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0

# Create the container
docker create --name RegtestInfinityPro \
  --publish 18443:18443 \
  --publish 18444:18444 \
  --publish 3002:3002 \
  --publish 3003:3003 \
  --publish 60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0

# Start the container
docker start RegtestInfinityPro

# Wait ~15 seconds for services to start
sleep 15
```

## Using the Just Command Runner

For the best experience, use the provided justfile which wraps all common commands:

### Setup

```bash
# Download the Docker-compatible justfile
curl -O https://raw.githubusercontent.com/thunderbiscuit/podman-regtest-infinity-pro/master/justfile-docker

# Rename it to 'justfile'
mv justfile-docker justfile

# Install just if you don't have it
# macOS: brew install just
# Linux: cargo install just
# See: https://github.com/casey/just
```

### Available Commands

Once you have the justfile, run `just` to see all available commands:

```bash
$ just

Available recipes:
    [Container]
    default        # List all available commands
    pull           # Pull the latest image from ghcr.io
    start          # Create and start the regtest container
    stop           # Stop the regtest container
    remove         # Remove the container (keeps the image)
    shell          # Enter the shell in the container
    explorer       # Open the block explorer

    [Docs]
    services       # List the available services and their endpoints

    [Bitcoin Core]
    cookie         # Print the current session cookie to console
    mine           # Mine a block, or mine <BLOCKS> number of blocks
    mineandsendrewardto # Send mining reward to <ADDRESS>
    cli            # Send a command to bitcoin-cli

    [Logs]
    logs           # Print all logs to console
    bitcoindlogs   # Print bitcoin daemon logs to console
    esploralogs    # Print Esplora logs to console
    explorerlogs   # Print block explorer logs to console

    [Default Wallet]
    createwallet   # Create a default wallet
    loadwallet     # Load the default wallet
    newaddress     # Print an address from the default wallet
    walletbalance  # Print the balance of the default wallet
    sendto         # Send bitcoin to ADDRESS using the default wallet
```

### Example Workflow

```bash
# Start the container
just start

# Mine some blocks
just mine 101

# Create a wallet
just createwallet

# Get a new address
just newaddress

# Mine to that address
just mineandsendrewardto bcrt1q...

# Check balance
just walletbalance

# View logs
just bitcoindlogs

# Open block explorer
just explorer

# Stop when done
just stop
```

## Manual Commands (Without Just)

If you prefer not to use just, here are the manual Docker commands:

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
  createwallet podmanwallet

# Get new address
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -rpcwallet=podmanwallet \
  getnewaddress

# Check balance
docker exec RegtestInfinityPro bitcoin-cli \
  --chain=regtest \
  --rpcuser=__cookie__ \
  --rpcpassword="$COOKIE" \
  -rpcwallet=podmanwallet \
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
  --publish 18443:18443 \
  --publish 18444:18444 \
  --publish 3002:3002 \
  --publish 3003:3003 \
  --publish 60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0
docker start RegtestInfinityPro
```

### Persistent Data

By default, the container does not persist data. To keep blockchain data between restarts:

```bash
# Create a volume
docker volume create bitcoin-regtest-data

# Create container with volume
docker create --name RegtestInfinityPro \
  --publish 18443:18443 \
  --publish 18444:18444 \
  --publish 3002:3002 \
  --publish 3003:3003 \
  --publish 60401:60401 \
  --volume bitcoin-regtest-data:/root/.bitcoin \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0
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
  --publish 28443:18443 \
  --publish 28444:18444 \
  --publish 13002:3002 \
  --publish 13003:3003 \
  --publish 50401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0
```

### Container Won't Start

Check logs for errors:

```bash
docker logs RegtestInfinityPro
```

## Using with Podman

The image works with Podman too - just replace `docker` with `podman`:

```bash
podman pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0
podman create --name RegtestInfinityPro \
  --publish 18443:18443 \
  --publish 18444:18444 \
  --publish 3002:3002 \
  --publish 3003:3003 \
  --publish 60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.1.0
podman start RegtestInfinityPro
```
