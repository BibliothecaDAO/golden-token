#!/bin/bash

ENV_FILE="/workspaces/golden-token/.env"

#Install scarb
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | bash -s -- -v 0.7.0

# Install starkli
curl https://get.starkli.sh | sh

# Change directory to starkli
cd /home/vscode/.starkli/bin/

# Execute starkliup
./starkliup

# If there is already an account in .env, skip that
if grep -q "^ACCOUNT_ADDRESS=" "$ENV_FILE"; then
    echo "Account already setup, exiting"
    return
fi

# If .env isn't setup yet, proceed to generate keypairs and set it up
echo "GOLDEN_TOKEN_NAME=86359915354906848020620654" > $ENV_FILE
echo "GOLDEN_TOKEN_SYMBOL=78543885460846" >> $ENV_FILE
echo "OWNER=0x020b96923a9e60f63a1829d440a03cf680768cadbc8fe737f71380258817d85b" >> $ENV_FILE
echo "DAO_ADDRESS=0x020b96923a9e60f63a1829d440a03cf680768cadbc8fe737f71380258817d85b" >> $ENV_FILE

# initialize starknet directories
mkdir -p $HOME/.starknet
STARKNET_ACCOUNT=$HOME/.starknet/account
STARKNET_KEYSTORE=$HOME/.starknet/keystore

# Generate keypair
output=$(./starkli signer gen-keypair)

# Store keys as vars so we can use them and later write to .bashrc
private_key=$(echo "$output" | awk '/Private key/ {print $4}')
public_key=$(echo "$output" | awk '/Public key/ {print $4}')

# Initialize OZ account and save output
account_output=$(./starkli account oz init $STARKNET_ACCOUNT --private-key $private_key 2>&1)
account_address=$(echo "$account_output" | grep -oE '0x[0-9a-fA-F]+')

# Deploy Account
./starkli account deploy $STARKNET_ACCOUNT --private-key $private_key

# Output key and account info
echo "Private Key:  $private_key"
echo "Public Key:   $public_key"
echo "Account:      $account_address"

# Add keys and account to .bashrc as env vars for easy access in shell
echo "PRIVATE_KEY=\"$private_key\"" >> $ENV_FILE
echo "PUBLIC_KEY=\"$public_key\"" >> $ENV_FILE
echo "ACCOUNT_ADDRESS=\"$account_address\"" >> $ENV_FILE
echo "STARKNET_ACCOUNT=$STARKNET_ACCOUNT" >> $ENV_FILE
echo "STARKNET_KEYSTORE=$STARKNET_KEYSTORE" >> $ENV_FILE

echo "set -o allexport" >> ~/.bashrc
echo "source $ENV_FILE" >> ~/.bashrc
echo "set +o allexport" >> ~/.bashrc

source ~/.bashrc