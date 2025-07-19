#!/bin/bash

# Contract Upgrade Script for StakCast Prediction Hub
# Make sure to update these variables before running

CONTRACT_ADDRESS="0x..." # Replace with your contract address
ADMIN_ACCOUNT="your_account_name"
KEYSTORE_PATH="path/to/your/keystore"
RPC_URL="https://starknet-mainnet.public.blastapi.io/rpc/v0_7" # or testnet URL

echo "Starting contract upgrade process..."

# Step 1: Build the contract
echo "Building contract..."
scarb build

# Step 2: Declare the new implementation
echo "Declaring new implementation..."
NEW_CLASS_HASH=$(starkli declare target/dev/stakcast_PredictionHub.contract_class.json \
    --account $ADMIN_ACCOUNT \
    --keystore $KEYSTORE_PATH \
    --rpc $RPC_URL \
    --watch | grep -o '0x[0-9a-fA-F]*' | tail -1)

echo "New class hash: $NEW_CLASS_HASH"

# Step 3: Verify the class hash is valid
if [ -z "$NEW_CLASS_HASH" ]; then
    echo "Error: Failed to get class hash"
    exit 1
fi

# Step 4: Optional - Pause contract for safety
echo "Consider pausing the contract before upgrade..."
echo "Uncomment the following line if you want to pause:"
# starkli invoke $CONTRACT_ADDRESS emergency_pause "Contract upgrade in progress" \
#     --account $ADMIN_ACCOUNT \
#     --keystore $KEYSTORE_PATH \
#     --rpc $RPC_URL

# Step 5: Perform the upgrade
echo "Performing contract upgrade..."
starkli invoke $CONTRACT_ADDRESS upgrade $NEW_CLASS_HASH \
    --account $ADMIN_ACCOUNT \
    --keystore $KEYSTORE_PATH \
    --rpc $RPC_URL \
    --watch

echo "Upgrade completed!"

# Step 6: Optional - Unpause contract
echo "Consider unpausing the contract after upgrade..."
echo "Uncomment the following line if you paused the contract:"
# starkli invoke $CONTRACT_ADDRESS emergency_unpause \
#     --account $ADMIN_ACCOUNT \
#     --keystore $KEYSTORE_PATH \
#     --rpc $RPC_URL

echo "Upgrade process finished!" 