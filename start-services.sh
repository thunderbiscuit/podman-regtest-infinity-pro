#!/bin/bash

# Create the log directory
mkdir /root/log/

# Start the bitcoin daemon
bitcoind --chain=regtest --txindex --blockfilterindex --peerblockfilters --rpcbind=0.0.0.0 --rpcallowip=0.0.0.0/0 --rpcport=18443 --rpcuser=regtest --rpcpassword=password --rest --printtoconsole > /root/log/bitcoin.log 2>&1 &
until bitcoin-cli -regtest -rpcuser=regtest -rpcpassword=password getblockchaininfo 2>/dev/null; do
  sleep 1
done

# Start the blockchain explorer
fbbe --network regtest --local-addr 0.0.0.0:3003 > /root/log/fbbe.log 2>&1 &

# Start the Esplora and Electrum services
electrs -vvvv --daemon-dir /root/.bitcoin/ --http-addr 0.0.0.0:3002 --electrum-rpc-addr 0.0.0.0:60401 --network=regtest --lightmode --cookie regtest:password > /root/log/esplora.log 2>&1 &

# Mine 101 blocks
bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password generatetoaddress 101 bcrt1q6gau5mg4ceupfhtyywyaj5ge45vgptvawgg3aq

wait
