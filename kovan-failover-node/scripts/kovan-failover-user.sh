#!/bin/bash
set -x
# Executed as Azure user.

ACCOUNT_WALLET=$(cat ~/key.json | sed 's@"@\\"@g')
ACCOUNT_PASSWORD="$2"

# Run Parity

parity daemon parity.pid --log-file parity.log --auto-update=all --force-sealing --chain kovan --jsonrpc-apis "web3,eth,net,personal,parity_set"

# Wait a few seconds to let Parity start
# TODO: find a better way

sleep 15

# Create account

json_request='{"jsonrpc":"2.0","method":"parity_newAccountFromWallet","params":["'${ACCOUNT_WALLET}'","'${ACCOUNT_PASSWORD}'"],"id":1}'
response=$(echo $json_request | nc -q 1 -U ./.local/share/io.parity.ethereum/jsonrpc.ipc)
address=$(echo $response | python -c 'import sys, json; print json.load(sys.stdin)["result"]')


# Run failover Node.JS app

git clone https://github.com/paritytech/kovan-failover.git
cd kovan-failover
npm install

cp pm2.template.js kovan-failover.json
sed -i "s/<address to scan for and sign with>/${address}/" kovan-failover.json
sed -i "s/<address to unlock the signer address>/${ACCOUNT_PASSWORD}/" kovan-failover.json



pm2 start kovan-failover.json

sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u parity --hp /home/parity

