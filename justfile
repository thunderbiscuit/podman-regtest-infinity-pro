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
[doc("Serve the local docs.")]
servedocs:
  mkdocs serve

[group("Pod")]
[doc("Start your podman machine and regtest environment.")]
start:
  podman machine start regtest
  podman --connection regtest start RegtestBitcoinEnv

[group("Pod")]
[doc("Stop your podman machine and regtest environment.")]
stop:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE stop
  podman --connection regtest stop RegtestBitcoinEnv
  podman machine stop regtest

[group("Pod")]
[doc("Enter the shell in the pod.")]
podshell:
  podman --connection regtest exec -it RegtestBitcoinEnv /bin/bash

[group("Pod")]
[doc("Open the block explorer.")]
explorer:
  open http://127.0.0.1:3003

[group("Bitcoin Core")]
[doc("Print the current session cookie to console.")]
@cookie:
  podman --connection regtest exec RegtestBitcoinEnv cat /root/.bitcoin/regtest/.cookie | cut -d ':' -f2

[group("Bitcoin Core")]
[doc("Mine a block, or mine <BLOCKS> number of blocks.")]
@mine BLOCKS="1":
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE generatetoaddress {{BLOCKS}} bcrt1q6gau5mg4ceupfhtyywyaj5ge45vgptvawgg3aq

[group("Bitcoin Core")]
[doc("Send mining reward to <ADDRESS>.")]
@sendminingrewardto ADDRESS:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE generatetoaddress 1 {{ADDRESS}}

[group("Bitcoin Core")]
[doc("Send a command to bitcoin-cli.")]
@cli COMMAND:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE {{COMMAND}}

[group("Logs")]
[doc("Print all logs to console.")]
logs:
  podman --connection regtest logs RegtestBitcoinEnv

[group("Logs")]
[doc("Print bitcoin daemon logs to console.")]
bitcoindlogs:
  podman --connection regtest exec -it RegtestBitcoinEnv tail -f /root/log/bitcoin.log

[group("Logs")]
[doc("Print Esplora logs to console.")]
esploralogs:
  podman --connection regtest exec -it RegtestBitcoinEnv tail -f /root/log/esplora.log

[group("Logs")]
[doc("Print block explorer logs to console.")]
explorerlogs:
  podman --connection regtest exec -it RegtestBitcoinEnv tail -f /root/log/fbbe.log

[group("Default Wallet")]
[doc("Create a default wallet.")]
@createwallet:
  COOKIE=$(just cookie) \
  && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE createwallet podmanwallet \
  && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE -rpcwallet=podmanwallet settxfee 0.0001

[group("Default Wallet")]
[doc("Load the default wallet.")]
@loadwallet:
  COOKIE=$(just cookie) \
  && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE loadwallet podmanwallet

[group("Default Wallet")]
[doc("Print an address from the default wallet.")]
@newaddress:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE -rpcwallet=podmanwallet getnewaddress

[group("Default Wallet")]
[doc("Print the balance of the default wallet.")]
@walletbalance:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE -rpcwallet=podmanwallet getbalance

[group("Default Wallet")]
[doc("Send 1 bitcoin to ADDRESS using the default wallet.")]
@sendto ADDRESS:
  COOKIE=$(just cookie) && bitcoin-cli --chain=regtest --rpcuser=__cookie__ --rpcpassword=$COOKIE -rpcwallet=podmanwallet -named sendtoaddress address={{ADDRESS}} amount=0.12345678 fee_rate=4
