# Usage

Start the podman machine and `RegtestInfinityPro` container to fire up all services:

```shell
cd ~/podman/podman-regtest-infinity-pro/
just start

# Alternatively, use
podman machine start regtest
podman start RegtestInfinityPro
```

Once started, the container runs four services automatically:

- Bitcoin Core daemon (listening on port `18443`)
- Electrum server (listening on port `60401`)
- Esplora server (listening on port `3002`)
- Fast Bitcoin Block Explorer (listening on port `3003`)

On the very first start (or after a `just reset`), the container automatically creates a faucet wallet and mines 101 blocks to it. This provides mature coins that can be instantly sent to any address without needing to mine additional blocks for coinbase maturity.

The blockchain persists across stops and starts: your blocks, wallets, and transactions are still there the next time you run `just start` (each start simply mines one additional block to the faucet). If you ever want to start over from a clean slate, use `just reset` — it wipes the chain data and the Esplora/Electrum index, then bootstraps a fresh network with a newly funded faucet.

## Quick Start Tutorial

Here's a complete workflow to get you started:

```shell
# Start the environment
just start

# Send funds from the faucet to any address (e.g. your wallet app under test)
just faucet bcrt1qxy2kgd... 5

# Mine a block to confirm the faucet transaction
just mine 1

# Need an address to send coins back to? Get one from the faucet wallet
just newaddress
# Output: bcrt1qtest...

# Check the faucet balance
just faucetbalance

# View the block explorer
just explorer
```

## Available Commands Reference

List all available commands:

```shell
$ just
Available recipes:
    [Repo]
    default                            # List all available commands.
    repo                               # Open repository on GitHub.

    [Pod]
    services                           # List the available services and their endpoints.
    start                              # Start your podman machine and regtest environment.
    stop                               # Stop your podman machine and regtest environment.
    reset                              # Reset the regtest network to a fresh state (wipes all blocks and wallets).
    podshell                           # Enter the shell in the pod.
    explorer                           # Open the block explorer.

    [Bitcoin Core]
    mine BLOCKS="1"                    # Mine a block, or mine <BLOCKS> number of blocks.
    mineandsendrewardto ADDRESS        # Send mining reward to <ADDRESS>.
    cli COMMAND                        # Send a command to bitcoin-cli.
    height                             # Print the height of the blockchain.

    [Logs]
    logs                               # Print all logs to console.
    bitcoindlogs                       # Print bitcoin daemon logs to console.
    esploralogs                        # Print Esplora logs to console.
    explorerlogs                       # Print block explorer logs to console.

    [Faucet]
    faucet ADDRESS AMOUNT="0.12345678" # Send bitcoin from the faucet wallet to ADDRESS.
    faucetbalance                      # Print the balance of the faucet wallet.
    newaddress                         # Print a new address from the faucet wallet.
```

## Container Management

### Starting and Stopping

```shell
# Start the environment
just start

# Stop the environment gracefully
just stop

# Check available services and their endpoints
just services
```

Example output from `just services`:
```
--- Accessible from this machine -------------------------------
Electrum server:                       tcp://127.0.0.1:60401
Esplora server:                        http://127.0.0.1:3002
Electrum server (Android emulators):   tcp://10.0.2.2:60401
Esplora server  (Android emulators):   http://10.0.2.2:3002
Fast Bitcoin Block Explorer:           http://127.0.0.1:3003

--- Accessible from your local network -------------------------
Bitcoin Core P2P:                      tcp://192.168.1.42:18444
Electrum server:                       tcp://192.168.1.42:60401
Esplora server:                        http://192.168.1.42:3002
Fast Bitcoin Block Explorer:           http://192.168.1.42:3003

--- Open the block explorer on your phone ----------------------
[QR code]
```

The command finishes by printing a QR code you can scan with your phone to open the block explorer directly (this requires [qrencode](https://github.com/fukuchi/libqrencode), available with `brew install qrencode`). See [Local Network Access](#local-network-access) for more on connecting from other devices.

### Resetting the Network

The blockchain persists across container stops and starts. To wipe everything and bootstrap a fresh network (new chain, new faucet wallet, 101 freshly mined blocks):

```shell
just reset
```

This deletes the chain data and the Esplora/Electrum index inside the container, then restarts it. Any wallets you created are deleted as well.

### Accessing the Container

```shell
# Enter the container shell
just podshell

# Once inside, you can access bitcoin-cli directly
bitcoin-cli --chain=regtest getblockchaininfo
```

## Working with Bitcoin Core

### Mining Blocks

```shell
# Mine a single block
just mine

# Mine multiple blocks
just mine 10

# Mine a block and send the reward to a specific address
just mineandsendrewardto bcrt1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh

# Check the current height of the blockchain
just height
```

### Using bitcoin-cli Commands

You can execute any bitcoin-cli command using the `just cli` command:

```shell
# Get blockchain information
just cli getblockchaininfo

# Get network information
just cli getnetworkinfo

# List all wallets
just cli listwallets

# Get mempool information
just cli getmempoolinfo

# Get a new address from the faucet wallet
just cli "-rpcwallet=faucet getnewaddress"

# Send a raw transaction
just cli sendrawtransaction <hex>

# Get block hash by height
just cli getblockhash 1

# Get block information
just cli getblock <blockhash>
```

## Using the Faucet Wallet

The container automatically creates a `faucet` wallet on startup with mature coins ready to spend. This is the recommended way to fund your test wallets.

### Why Use the Faucet?

Mining blocks to get coins requires waiting for coinbase maturity (100 blocks). The faucet wallet already has mature coins from startup, so you can get funds instantly with just one confirmation block.

**Without faucet (slow):**
```shell
just mineandsendrewardto <your-address>
just mine 100  # Wait for coinbase maturity
```

**With faucet (fast):**
```shell
just faucet <your-address> 5
just mine 1  # Just confirm the transaction
```

### Faucet Commands

```shell
# Send the default amount (0.12345678 BTC) to an address
just faucet bcrt1qxy2kgd...

# Send a specific amount
just faucet bcrt1qxy2kgd... 10

# Check faucet balance
just faucetbalance

# Get a new address from the faucet wallet
# (e.g. as a target when testing sends from your own wallet app)
just newaddress
# Example output: bcrt1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
```

The faucet starts with approximately 50 BTC of spendable coins from the initial 101 mined blocks. Coins sent to a `just newaddress` address go back into the faucet, topping it up.

### Complete Workflow Example

Testing a wallet application end to end:

```shell
# Fund your application's wallet (coins are already mature, no need to mine 101 blocks)
just faucet <your-app-address> 10

# Mine a block to confirm the faucet transaction
just mine 1

# Get an address to test sending funds back
ADDRESS=$(just newaddress)
echo "Address: $ADDRESS"

# ... send from your application to $ADDRESS ...

# Mine a block to confirm
just mine 1
```

### Need a Second Wallet?

The faucet is the only wallet the environment manages for you. If you want an additional node wallet — for example to simulate a second party with its own balance — create one directly with bitcoin-cli:

```shell
just cli "createwallet mywallet"
just cli "-rpcwallet=mywallet getnewaddress"
```

## Viewing Logs

Monitor what's happening inside the container:

```shell
# View all container logs
just logs

# Follow Bitcoin Core logs in real-time
just bitcoindlogs

# Follow Esplora server logs
just esploralogs

# Follow block explorer logs
just explorerlogs
```

To exit from log following (when using `tail -f`), press `Ctrl+c`.

## Using the Services

### Block Explorer

Open the Fast Bitcoin Block Explorer in your browser:

```shell
just explorer
```

This opens `http://127.0.0.1:3003` where you can browse blocks, transactions, and addresses.

### Electrum Server

Connect your Electrum wallet or any SPV client to:
```
tcp://127.0.0.1:60401
```

For Android emulators, use:
```
tcp://10.0.2.2:60401
```

### Esplora Server

The Esplora REST API is available at:

```
http://127.0.0.1:3002
```

Example API calls:

```shell
# Get blockchain tip
curl http://127.0.0.1:3002/blocks/tip/height

# Get block by hash
curl http://127.0.0.1:3002/block/<blockhash>

# Get address info
curl http://127.0.0.1:3002/address/<address>

# Get transaction
curl http://127.0.0.1:3002/tx/<txid>
```

For Android emulators, use:

```
http://10.0.2.2:3002
```

## Local Network Access

The services are reachable from other devices on your local network out of the box — no extra configuration needed. The `--publish` flags used when creating the container bind the ports on all of the host's interfaces, so a phone or laptop on the same Wi-Fi can connect using your machine's LAN IP address (for example `192.168.1.42` below).

This is particularly useful for testing mobile apps on real hardware instead of an emulator:

- **Compact block filter (BIP-157/158) clients** can use the node as a peer at `192.168.1.42:18444`. The node runs with `blockfilterindex` and `peerblockfilters`, so it serves filters to any CBF wallet that connects.
- **Electrum wallets** can connect to `tcp://192.168.1.42:60401`.
- **Esplora-based apps** can use `http://192.168.1.42:3002`.
- **The block explorer** is at `http://192.168.1.42:3003` in any browser on the network.

Run `just services` to see all endpoints with your actual LAN IP filled in, along with a QR code that opens the block explorer on your phone.

!!! warning "Untrusted networks"
    These ports are open to *every* device on whatever network your machine is connected to — including the RPC port (18443), which uses well-known credentials and gives full control of the node. That's harmless on your home network with a valueless regtest chain, but on public Wi-Fi (café, conference) consider stopping the environment with `just stop` while you're connected, or enabling your operating system's firewall. You can also restrict individual ports to your own machine by publishing them on the loopback interface when creating the container (e.g. `--publish 127.0.0.1:18443:18443` instead of `--publish 0.0.0.0:18443:18443`) — the RPC port is the best candidate, since none of the phone-facing services need it.

Two things that can get in the way of connecting from another device: some networks (typically office or guest Wi-Fi) enable *client isolation*, which blocks devices from talking to each other; and your machine's firewall may need to allow incoming connections for podman's `gvproxy` process.

## Advanced Usage

### RPC Authentication

Bitcoin Core runs with static RPC credentials: username `regtest`, password `password`. All the `just` commands use these under the hood, and you can use them directly from any RPC client:

```shell
bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password getblockchaininfo

# Or over raw HTTP
curl --user regtest:password \
  --data-binary '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}' \
  -H 'content-type: text/plain;' http://127.0.0.1:18443/
```

### Custom bitcoin-cli Commands

Execute any bitcoin-cli command with custom RPC wallet:

```shell
# Create a new wallet
just cli "createwallet "myotherwallet""

# Use that wallet
just cli "-rpcwallet=myotherwallet getnewaddress"
```

### Creating Local Custom Commands

You can extend the `justfile` with your own custom commands that won't be committed to the repository.

Create a `justfile.local` file in the project root:

```shell
touch justfile.local
```

Add it to `.gitignore` so it stays local:

```shell
echo "justfile.local" >> .gitignore
```

Then add your custom commands to `justfile.local`. For example:

```just
# Check the health of all services
@ping:
  #!/usr/bin/env bash
  if podman --connection regtest ps --format "{{{{.Names}}}}" | grep -q "^RegtestInfinityPro$"; then
    echo "✓ Container running"
  else
    echo "✗ Container not running"
  fi
```

The main `justfile` already imports `justfile.local` (if it exists), so all your custom commands will appear when you run `just --list`.
