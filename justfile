import? "justfile.local"

[group("Repo")]
[doc("List all available commands.")]
@default:
  just --list --unsorted

[group("Repo")]
[doc("Open repository on GitHub.")]
repo:
  open https://github.com/thunderbiscuit/podman-regtest-infinity-pro/

[group("Pod")]
[doc("List the available services and their endpoints.")]
services:
  #!/usr/bin/env bash
  LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1)
  echo ""
  echo "--- Accessible from this machine -------------------------------"
  echo "Electrum server:                       tcp://127.0.0.1:60401"
  echo "Esplora server:                        http://127.0.0.1:3002"
  echo "Electrum server (Android emulators):   tcp://10.0.2.2:60401"
  echo "Esplora server  (Android emulators):   http://10.0.2.2:3002"
  echo "Fast Bitcoin Block Explorer:           http://127.0.0.1:3003"
  echo ""
  echo "--- Accessible from your local network -------------------------"
  echo "Bitcoin Core P2P:                      tcp://$LAN_IP:18444"
  echo "Electrum server:                       tcp://$LAN_IP:60401"
  echo "Esplora server:                        http://$LAN_IP:3002"
  echo "Fast Bitcoin Block Explorer:           http://$LAN_IP:3003"
  echo ""
  echo "--- Open the block explorer on your phone ----------------------"
  echo ""
  qrencode -t ansiutf8 "http://$LAN_IP:3003"

[group("Pod")]
[doc("Start your podman machine and regtest environment.")]
start:
  #!/usr/bin/env bash
  if podman machine inspect regtest | jq --exit-status '.[0].State == "stopped"' > /dev/null; then
    podman machine start regtest
    podman --connection regtest start RegtestInfinityPro
  else
    echo "Machine is already running..."
  fi

[group("Pod")]
[doc("Stop your podman machine and regtest environment.")]
stop:
  #!/usr/bin/env bash
  if podman machine inspect regtest | jq --exit-status '.[0].State == "running"' > /dev/null; then
    bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password stop
    podman --connection regtest stop RegtestInfinityPro
    podman machine stop regtest
  else
    echo "Machine is already stopped..."
  fi

[group("Pod")]
[doc("Reset the regtest network to a fresh state (wipes all blocks and wallets).")]
reset:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Stopping the Bitcoin daemon..."
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password stop || true
  echo "Waiting for the daemon to shut down..."
  until ! bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password getblockchaininfo > /dev/null 2>&1; do
    sleep 1
  done
  echo "Deleting the regtest chain data and the Esplora/Electrum index..."
  podman --connection regtest exec RegtestInfinityPro rm -rf /root/.bitcoin/regtest /db/regtest
  echo "Restarting the container to bootstrap a fresh network..."
  podman --connection regtest restart RegtestInfinityPro
  echo "Done. A fresh regtest network is bootstrapping."

[group("Pod")]
[doc("Enter the shell in the pod.")]
podshell:
  podman --connection regtest exec -it RegtestInfinityPro /bin/bash

[group("Pod")]
[doc("Open the block explorer.")]
explorer:
  open http://127.0.0.1:3003

[group("Bitcoin Core")]
[doc("Mine a block, or mine <BLOCKS> number of blocks.")]
@mine BLOCKS="1":
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password generatetoaddress {{BLOCKS}} bcrt1q6gau5mg4ceupfhtyywyaj5ge45vgptvawgg3aq

[group("Bitcoin Core")]
[doc("Send mining reward to <ADDRESS>.")]
@mineandsendrewardto ADDRESS:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password generatetoaddress 1 {{ADDRESS}}

[group("Bitcoin Core")]
[doc("Send a command to bitcoin-cli.")]
@cli COMMAND:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password {{COMMAND}}

[group("Bitcoin Core")]
[doc("Print the height of the blockchain.")]
@height:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password getblockcount

[group("Logs")]
[doc("Print all logs to console.")]
logs:
  podman --connection regtest exec -it RegtestInfinityPro tail -f /root/log/bitcoin.log /root/log/fbbe.log /root/log/esplora.log

[group("Logs")]
[doc("Print bitcoin daemon logs to console.")]
bitcoindlogs:
  podman --connection regtest exec -it RegtestInfinityPro tail -f /root/log/bitcoin.log

[group("Logs")]
[doc("Print Esplora logs to console.")]
esploralogs:
  podman --connection regtest exec -it RegtestInfinityPro tail -f /root/log/esplora.log

[group("Logs")]
[doc("Print block explorer logs to console.")]
explorerlogs:
  podman --connection regtest exec -it RegtestInfinityPro tail -f /root/log/fbbe.log

[group("Faucet")]
[doc("Send bitcoin from the faucet wallet to ADDRESS.")]
@faucet ADDRESS AMOUNT="0.12345678":
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=faucet -named sendtoaddress address={{ADDRESS}} amount={{AMOUNT}} fee_rate=4

[group("Faucet")]
[doc("Print the balance of the faucet wallet.")]
@faucetbalance:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=faucet getbalance

[group("Faucet")]
[doc("Print a new address from the faucet wallet.")]
@newaddress:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=faucet getnewaddress
