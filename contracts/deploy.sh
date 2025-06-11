#!/bin/bash

# ---- CONFIGURATION ----
ACCOUNT_ALIAS="myaccount"  # Your Starkli account alias
NETWORK="sepolia"
ERC20_COMPILED="./target/dev/MockERC20.contract_class.json"
HUB_COMPILED="./target/dev/PredictionHub.contract_class.json"

# Addresses for constructor
ADMIN="0x0123..."           # Replace with your admin address
FEE_RECIPIENT="0x0456..."   # Replace with your fee recipient address
PRAGMA_ORACLE="0x0789..."   # Replace with your oracle address

# ---- 1. Declare and Deploy ERC20 Token ----

echo "Declaring ERC20..."
ERC20_DECLARE_OUTPUT=$(starkli declare --account $ACCOUNT_ALIAS --network $NETWORK $ERC20_COMPILED)
ERC20_CLASS_HASH=$(echo "$ERC20_DECLARE_OUTPUT" | grep "Class hash:" | awk '{print $3}')

echo "Deploying ERC20..."
# ERC20 constructor: recipient (address to receive initial supply)
ERC20_DEPLOY_OUTPUT=$(starkli deploy --account $ACCOUNT_ALIAS --network $NETWORK $ERC20_CLASS_HASH $ADMIN)
ERC20_ADDRESS=$(echo "$ERC20_DEPLOY_OUTPUT" | grep "Contract address:" | awk '{print $3}')

echo "ERC20 deployed at: $ERC20_ADDRESS"

# ---- 2. Declare and Deploy PredictionHub ----

echo "Declaring PredictionHub..."
HUB_DECLARE_OUTPUT=$(starkli declare --account $ACCOUNT_ALIAS --network $NETWORK $HUB_COMPILED)
HUB_CLASS_HASH=$(echo "$HUB_DECLARE_OUTPUT" | grep "Class hash:" | awk '{print $3}')

echo "Deploying PredictionHub..."
HUB_DEPLOY_OUTPUT=$(starkli deploy --account $ACCOUNT_ALIAS --network $NETWORK $HUB_CLASS_HASH $ADMIN $FEE_RECIPIENT $PRAGMA_ORACLE $ERC20_ADDRESS)
HUB_ADDRESS=$(echo "$HUB_DEPLOY_OUTPUT" | grep "Contract address:" | awk '{print $3}')

echo "PredictionHub deployed at: $HUB_ADDRESS"