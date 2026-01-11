#!/bin/bash

# Create the log directory
mkdir ~/log/

# Start the bitcoin daemon
bitcoind --chain=regtest --txindex --blockfilterindex --peerblockfilters --rpcbind=0.0.0.0 --rpcallowip=0.0.0.0/0 --rpcport=18443 --rpcuser=regtest --rpcpassword=password --rest --printtoconsole > ~/log/bitcoin.log 2>&1 &
sleep 10

# Start the blockchain explorer
/root/fbbe/target/release/fbbe --network regtest --local-addr 0.0.0.0:3003 > ~/log/fbbe.log 2>&1 &
sleep 10

# Start the Esplora and Electrum services
/root/electrs/target/release/electrs -vvvv --daemon-dir /root/.bitcoin/ --http-addr 0.0.0.0:3002 --electrum-rpc-addr 0.0.0.0:60401 --network=regtest --lightmode --cookie regtest:password > ~/log/esplora.log 2>&1 &
sleep 10

# Mine 3 blocks
bitcoin-cli --chain=regtest --rpcuser=regtest --rpcpassword=password generatetoaddress 3 bcrt1q6gau5mg4ceupfhtyywyaj5ge45vgptvawgg3aq

wait
