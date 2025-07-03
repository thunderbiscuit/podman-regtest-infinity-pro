# Usage

Start the podman machine and `RegtestBitcoinEnv` container to fire up all services:

```shell
cd ~/podman/podman-regtest-infinity-pro/
just start

# Alternatively, use
podman machine start regtest
podman start RegtestBitcoinEnv
```

## Commands

The best way to explore what the regtest environment can do is to take a look at the `justfile` in the root of the repository, or use the `just` command to list all available commands.

```shell
❯ just
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
