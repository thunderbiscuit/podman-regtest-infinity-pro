[group("Repo")]
[doc("List all available commands.")]
@default:
  just --list --unsorted

[group("Repo")]
[doc("Open repository on GitHub.")]
repo:
  open https://github.com/thunderbiscuit/podman-regtest-infinity-pro/

[group("Docs")]
[doc("List the available services and their endpoints.")]
@services:
  echo "Electrum server:                       tcp://127.0.0.1:60401"
  echo "Esplora server:                        http://127.0.0.1:3002"
  echo "Electrum server (Android emulators):   tcp://10.0.2.2:60401"
  echo "Esplora server  (Android emulators):   http://10.0.2.2:3002"
  echo "Fast Bitcoin Block Explorer:           http://127.0.0.1:3003"

[group("Docs")]
[doc("Build the local docs.")]
builddocs:
  uv run zensical build

[group("Docs")]
[doc("Serve the local docs.")]
servedocs:
  uv run zensical serve

[group("Pod")]
[doc("Start your podman machine and regtest environment.")]
start:
  podman machine start regtest
  podman --connection regtest start RegtestInfinityPro

[group("Pod")]
[doc("Stop your podman machine and regtest environment.")]
stop:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password stop
  podman --connection regtest stop RegtestInfinityPro
  podman machine stop regtest

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

[group("Logs")]
[doc("Print all logs to console.")]
logs:
  podman --connection regtest logs RegtestInfinityPro

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

[group("Default Wallet")]
[doc("Create a default wallet.")]
@createwallet:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password createwallet podmanwallet
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=podmanwallet settxfee 0.0001

[group("Default Wallet")]
[doc("Load the default wallet.")]
@loadwallet:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password loadwallet podmanwallet

[group("Default Wallet")]
[doc("Print an address from the default wallet.")]
@newaddress:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=podmanwallet getnewaddress

[group("Default Wallet")]
[doc("Print the balance of the default wallet.")]
@walletbalance:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=podmanwallet getbalance

[group("Default Wallet")]
[doc("Send bitcoin to ADDRESS using the default wallet.")]
@sendto ADDRESS:
  bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password -rpcwallet=podmanwallet -named sendtoaddress address={{ADDRESS}} amount=0.12345678 fee_rate=4
