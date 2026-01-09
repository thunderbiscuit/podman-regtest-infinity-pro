# Usage

Start the podman machine and `RegtestBitcoinEnv` container to fire up all services:

```shell
cd ~/podman/podman-regtest-infinity-pro/
just start

# Alternatively, use
podman machine start regtest
podman start RegtestBitcoinEnv
```

Once started, the container runs four services automatically:

- Bitcoin Core daemon (listening on port `18443`)
- Electrum server (listening on port `60401`)
- Esplora server (listening on port `3002`)
- Fast Bitcoin Block Explorer (listening on port `3003`)

The container also automatically mines 3 initial blocks on startup to get the blockchain going.

## Quick Start Tutorial

Here's a complete workflow to get you started:

```shell
# Start the environment
just start

# Create a wallet
just createwallet

# Mine some blocks (need 101 blocks for coinbase maturity)
just mine 101

# Get a new address
just newaddress
# Output: bcrt1qxy2kgd...

# Send bitcoin to another address
just sendto bcrt1qtest...

# Check your wallet balance
just walletbalance
# Output: 0.12345678

# Mine a block to confirm the transaction
just mine 1

# View the block explorer
just explorer
```

## Available Commands Reference

List all available commands:

```shell
$ just
Available recipes:
    [Podman]
    default                    # List all available commands.
    services                   # List the available services and their endpoints.
    start                      # Start your podman machine and regtest environment.
    stop                       # Stop your podman machine and regtest environment.
    podshell                   # Enter the shell in the pod.
    explorer                   # Open the block explorer.

    [Bitcoin Core]
    cookie                     # Print the current session cookie to console.
    mine BLOCKS="1"            # Mine a block, or mine <BLOCKS> number of blocks.
    sendminingrewardto ADDRESS # Send mining reward to <ADDRESS>
    cli COMMAND                # Send a command to bitcoin-cli

    [Logs]
    logs                       # Print all logs to console.
    bitcoindlogs               # Print bitcoin daemon logs to console.
    esploralogs                # Print Esplora logs to console.
    explorerlogs               # Print block explorer logs to console.

    [Docs]
    servedocs                  # Serve the local docs.
    docs                       # Open the website for docs.

    [Default Wallet]
    createwallet               # Create a default wallet.
    loadwallet                 # Load the default wallet.
    newaddress                 # Print an address from the default wallet.
    walletbalance              # Print the balance of the default wallet.
    sendto ADDRESS             # Send 1 bitcoin to ADDRESS using the default wallet.
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
Electrum server:                       tcp://127.0.0.1:60401
Esplora server:                        http://127.0.0.1:3002
Electrum server (Android emulators):   tcp://10.0.2.2:60401
Esplora server  (Android emulators):   http://10.0.2.2:3002
Fast Bitcoin Block Explorer:           http://127.0.0.1:3003
```

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

# Get a new address (requires wallet to be loaded)
just cli -rpcwallet=podmanwallet getnewaddress

# Send a raw transaction
just cli sendrawtransaction <hex>

# Get block hash by height
just cli getblockhash 1

# Get block information
just cli getblock <blockhash>
```

## Working with the Default Wallet

The environment supports creating and using a default wallet called `podmanwallet`.

### Wallet Setup

```shell
# Create the default wallet (only needed once)
just createwallet

# Load the wallet (if it already exists)
just loadwallet
```

### Wallet Operations

```shell
# Generate a new receiving address
just newaddress
# Example output: bcrt1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh

# Check wallet balance
just walletbalance
# Example output: 50.00000000

# Send 0.12345678 BTC to an address
just sendto bcrt1qtest...
# Note: The sendto command sends 0.12345678 BTC with a fee rate of 4 sat/vB
```

### Complete Wallet Workflow Example

```shell
# Create and load wallet
just createwallet

# Generate an address
ADDRESS=$(just newaddress)
echo "Address: $ADDRESS"

# Mine 1 block to a given address
just mineandsendrewardto $ADDRESS

# Check balance
just walletbalance

# Send funds somewhere else
just sendto bcrt1qrecipient...

# Mine a block to confirm
just mine 1
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

## Advanced Usage

### Getting the Authentication Cookie

Bitcoin Core uses cookie authentication. To get the current session cookie:

```shell
just cookie
```

You can use this cookie to authenticate RPC calls from outside the container:

```shell
COOKIE=$(just cookie)
bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE getblockchaininfo
```

### Custom bitcoin-cli Commands

Execute any bitcoin-cli command with custom RPC wallet:

```shell
# Create a new wallet
just cli "createwallet "myotherwallet""

# Use that wallet
just cli "-rpcwallet=myotherwallet getnewaddress"
```
