# Architecture

This page provides technical details about how the Podman Regtest Infinity Pro environment is structured and how its components interact.

## Overview

The environment consists of a single Podman container running multiple Bitcoin-related services that work together to provide a complete regtest development environment. All services run on a Debian Bookworm base image.

## Container Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│ Podman Container: RegtestInfinityPro                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Bitcoin Core Daemon (bitcoind)                              │  │
│  │ - Port: 18443 (RPC), 18444 (P2P)                            │  │
│  │ - username: regtest, password: password                     │  │
│  │ - txindex, blockfilterindex, compact block filters          │  │
│  └─────────────────────────────────────────────────────────────┘  │
│         │                                                         │
│         │ (RPC connections)                                       │
│         ├──────────────┬───────────────┬───────────────┐          │
│         ▼              ▼               ▼               ▼          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │ Electrum    │ │ Esplora     │ │ Block       │ │ External    │  │
│  │ Server      │ │ Server      │ │ Explorer    │ │ Tools       │  │
│  │ (electrs)   │ │ (electrs)   │ │ (fbbe)      │ │ (bitcoin-   │  │
│  │             │ │             │ │             │ │ cli)        │  │
│  │ Port: 60401 │ │ Port: 3002  │ │ Port: 3003  │ │             │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
         │              │              │
         │              │              │
         ▼              ▼              ▼
    Your Bitcoin   Your Web     Block Explorer
      Wallet       Application    in Browser
```

## Services

### 1. Bitcoin Core Daemon

**Purpose**: The backbone of the environment, running a full Bitcoin node in regtest mode.

**Configuration**:
- Chain: `regtest`
- RPC Port: `18443`
- P2P Port: `18444` (used by compact block filter clients connecting as peers)
- Authentication: static RPC credentials (username `regtest`, password `password`)
- Special features:
  - `txindex`: Full transaction index for looking up any transaction
  - `blockfilterindex`: Indexes for compact block filters
  - `peerblockfilters`: Serves compact block filters to peers
  - REST API enabled

**Location in Container**: `/usr/local/bin/bitcoind`

**Data Directory**: `/root/.bitcoin/regtest/`

**Startup**: Automatically started by `start-services.sh` with output redirected to `/root/log/bitcoin.log`

### 2. Electrum Server (electrs)

**Configuration**:
- Port: `60401` (Electrum RPC)
- Network: `regtest`
- Mode: `lightmode` (faster indexing for regtest)
- Daemon directory: `/root/.bitcoin/`

**Repository**: [Blockstream/electrs](https://github.com/Blockstream/electrs) (pinned to a specific commit of the `new-index` branch in the Containerfile)

**Location in Container**: `/usr/local/bin/electrs`

**Startup**: Started by `start-services.sh` with verbose logging (`-vvvv`) to `/root/log/esplora.log`

**Use Cases**:
- Testing Bitcoin wallets that use Electrum protocol
- SPV wallet development
- Mobile wallet testing

### 3. Esplora Server (electrs HTTP API)

**Configuration**:
- Port: `3002` (HTTP)
- Network: `regtest`
- Mode: `lightmode`

**Repository**: Same as Electrum server (electrs provides both services)

**Startup**: Same process as Electrum server (electrs serves both protocols)

**API Endpoints**:
- `/blocks/tip/height` - Get current blockchain height
- `/block/{hash}` - Get block by hash
- `/block/{hash}/txs` - Get transactions in a block
- `/tx/{txid}` - Get transaction details
- `/address/{address}` - Get address information
- `/address/{address}/txs` - Get address transactions
- `/fee-estimates` - Get fee estimates

**Use Cases**:
- Testing web applications that consume blockchain data
- Mobile app backend testing
- Block explorer integration

### 4. Fast Bitcoin Block Explorer (fbbe)

**Configuration**:
- Port: `3003`
- Network: `regtest`
- Listen address: `0.0.0.0:3003`

**Repository**: [RCasatta/fbbe](https://github.com/RCasatta/fbbe) (pinned to a specific commit in the Containerfile)

**Location in Container**: `/usr/local/bin/fbbe`

**Startup**: Started by `start-services.sh` with output to `/root/log/fbbe.log`

**Use Cases**:
- Visual inspection of blocks and transactions
- Debugging transaction issues
- Verifying confirmations

## Port Mapping

The container exposes the following ports to the host:

| Service          | Internal Port | Host Port | Protocol | Purpose                         |
|------------------|---------------|-----------|----------|---------------------------------|
| Bitcoin Core RPC | 18443         | 18443     | HTTP     | RPC commands                    |
| Bitcoin Core P2P | 18444         | 18444     | TCP      | P2P network (serves compact block filters to peers) |
| Esplora API      | 3002          | 3002      | HTTP     | REST API for blockchain data    |
| Block Explorer   | 3003          | 3003      | HTTP     | Web UI for browsing blocks      |
| Electrum Server  | 60401         | 60401     | TCP      | Electrum protocol               |

### Android Emulator Access

Android emulators can access the container services using the special IP `10.0.2.2`:
- Electrum: `tcp://10.0.2.2:60401`
- Esplora: `http://10.0.2.2:3002`

## Distribution

Pre-built container images are automatically published to GitHub Container Registry (ghcr.io) when new versions are tagged. This allows users to skip the lengthy build process and pull ready-to-use images directly.

### Published Images

Images are available at:
```
ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:{version}
```

### Available Versions

- `0.4.0` - Specific version (full semantic versioning)

### Publishing Workflow

Images are published automatically via GitHub Actions when tags are pushed:

1. **Trigger**: Push a tag matching `v*` (e.g., `v1.1.0`)
2. **Build**: GitHub Actions builds the container using Docker Buildx
3. **Push**: Image is pushed to ghcr.io with the exact version tag
4. **Cache**: Build cache is stored to speed up subsequent builds

Manual builds via `workflow_dispatch` create a `test` tag for development purposes.

The workflow uses:
- Bitcoin Core version: `29.2` (default)
- Target architecture: `x86_64-linux-gnu` (default for CI)

See `.github/workflows/publish-container.yml` for the complete workflow configuration.

### Benefits for CI/CD

Using pre-built images in continuous integration:
- **Fast**: Pull in seconds vs 15-30 minute build
- **Reproducible**: Same image across all environments
- **Resource-efficient**: Saves CI runner time and compute
- **Free**: GitHub Container Registry is free for public repos

## Build Process

The container is built using the Containerfile with two important build arguments:

### Build Arguments

**BITCOIN_VERSION**: Specifies which version of Bitcoin Core to install
- Examples: `28.1`, `27.0`, `29.0`
- Downloads from: `https://bitcoincore.org/bin/bitcoin-core-{VERSION}/`

**TARGET_ARCH**: Specifies the architecture of Bitcoin Core binaries
- Examples: `x86_64-linux-gnu`, `aarch64-linux-gnu`, `arm64-apple-darwin`
- Must match available builds at bitcoincore.org

### Build Stages

The Containerfile uses a two-stage build to keep the final image small:

**Builder stage** (Debian Bookworm):

1. Installs build dependencies (wget, curl, git, build-essential, OpenSSL and libclang headers)
2. Downloads the specified Bitcoin Core version and architecture from bitcoincore.org and extracts it to `/opt/bitcoin-{VERSION}/`
3. Installs the Rust toolchain (version 1.92.0)
4. Clones and builds electrs (Blockstream fork, pinned to a specific commit of the `new-index` branch) in release mode
5. Clones and builds fbbe (pinned to a specific commit) in release mode

**Runtime stage** (Debian Bookworm slim):

1. Installs only runtime dependencies (libssl3, netcat)
2. Copies the Bitcoin Core, electrs, and fbbe binaries from the builder stage into `/usr/local/bin/`
3. Copies `start-services.sh` as the entrypoint

Build tools, source trees, and intermediate artifacts stay in the builder stage and are not part of the final image.

## Startup Sequence

When the container starts, the `start-services.sh` script executes:

1. **Create Log Directory** (`/root/log/`)
2. **Start Bitcoin Core Daemon**
   - Runs in background with logging to `bitcoin.log`
   - The script polls `getblockchaininfo` once per second until the daemon responds
3. **Start Block Explorer (fbbe) and Electrs (Electrum + Esplora)**
   - Both start in parallel once bitcoind is ready, logging to `fbbe.log` and `esplora.log`
4. **Fund the Faucet Wallet**
   - On a fresh chain (block height 0): creates a wallet named `faucet` with `load_on_startup=true` and mines 101 blocks to it, providing mature coins for instant funding of test wallets
   - On subsequent starts: the existing faucet wallet auto-loads and a single new block is mined to it

## Resource Requirements

### Minimum Resources

Based on the `podman machine init` command in the install docs:
- **CPUs**: 4 cores
- **Memory**: 4096 MB (4 GB)
- **Disk**: 20 GB

### Actual Usage

The actual resource usage is typically lower:
- Bitcoin Core in regtest mode uses minimal resources
- Electrs indexing is fast in lightmode
- Total container size after build: ~2-3 GB

## Data Persistence

The blockchain **persists** between container stops and starts: blocks, wallets, and transactions survive a `just stop` / `just start` cycle because they live in the container's filesystem. The data is only lost if the container itself is removed, or explicitly wiped with `just reset` — which deletes the chain data and Esplora/Electrum index and restarts the container to bootstrap a fresh network.

### Data Locations (inside container)

- Bitcoin data: `/root/.bitcoin/regtest/`
- Electrs/Esplora index: `/db/regtest/`
- Logs: `/root/log/`

## Network Exposure

The container runs on Podman's default network, with services exposed to the host through port mappings. Because the ports are published on `0.0.0.0` (all interfaces), they are reachable not only from the host machine but also from **other devices on your local network** via the host's LAN IP address — this is what enables testing mobile apps on real hardware against the regtest node. Run `just services` to see the LAN endpoints.

## Logging

All services log to `/root/log/` inside the container:

| Service | Log File | Access Command |
|---------|----------|----------------|
| Bitcoin Core | `bitcoin.log` | `just bitcoindlogs` |
| Electrs (Esplora + Electrum) | `esplora.log` | `just esploralogs` |
| Block Explorer | `fbbe.log` | `just explorerlogs` |
| All services | All files | `just logs` |

## Security Considerations

This environment is designed for **local development only**:

- All ports are published on `0.0.0.0`, making every service reachable from any device on the network your machine is connected to
- The RPC port (18443) uses well-known credentials (`regtest`/`password`) and gives full control of the node — fine at home, but on untrusted networks (café, conference Wi-Fi) consider stopping the environment with `just stop` or enabling your OS firewall
- No authentication on Electrum/Esplora/Explorer services
- Not suitable for production or public exposure
- Do not use real Bitcoin private keys or mainnet data

## Extending the Environment

### Adding Custom Bitcoin Core Configuration

Edit the `start-services.sh` script to add flags to the `bitcoind` command:

```bash
bitcoind --chain=regtest \
  --txindex \
  --blockfilterindex \
  --peerblockfilters \
  --rpcbind=0.0.0.0 \
  --rpcallowip=0.0.0.0/0 \
  --rpcport=18443 \
  --rest \
  --printtoconsole \
  --maxmempool=50 \  # Add custom options
  > ~/log/bitcoin.log 2>&1 &
```

### Adding Additional Services

You can modify the Containerfile to install additional tools:

1. Install dependencies in the `RUN apt-get install` section
2. Build/install your service
3. Add startup commands to `start-services.sh`
4. Expose additional ports in the container create command

### Version Updates

To use a different Bitcoin Core version:

```shell
# Rebuild with different version
podman --connection regtest build \
  --build-arg BITCOIN_VERSION=27.0 \
  --build-arg TARGET_ARCH=x86_64-linux-gnu \
  --tag localhost/regtest:v0.1.0 \
  --file ./Containerfile
```

Then recreate the container with the new image.
