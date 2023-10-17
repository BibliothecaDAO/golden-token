#!/bin/bash

# Source env vars
ENV_FILE="/workspaces/golden-token/.env"
source $ENV_FILE

# Build project
cd /workspaces/golden-token/
scarb build

# Declare contract
cd ~/.starkli/bin/
declare_output=$(./starkli declare /workspaces/golden-token/target/dev/goldenToken_ERC721.sierra.json --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY 2>&1)

# Extract class hash from declare output
class_hash=$(echo "$declare_output" | grep -oE '0x[0-9a-fA-F]+')

# Deploy contract
./starkli deploy $class_hash $GOLDEN_TOKEN_NAME $GOLDEN_TOKEN_SYMBOL $OWNER $DAO_ADDRESS $ETH_ADDRESS --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY
