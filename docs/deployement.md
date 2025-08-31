# Deployment Guide for Stakcast

## Prerequisites
- Nodejs, pnpm
- Cairo and Scarb
- snforge(for testing)
- StarkNet wallet(ArgentX, Braavos)
- StarkNet CLI tools

---

## Local Devnet Setup
We recommend using [Katana](https://github.com/dojoengine/katana):

```bash
katana --seed 0
```
## Deployment Steps
1. Build Contracts
```bash
cd contracts
scarb build
```
2. Deploy to testnet
```bash
starknet deploy --contract target/dev/starkcast.json --network testnet
```
3. Record deployed address
Save contract address in /deployments/addresses.json

4. Verify deployment
```bash
starkent call --address <contract-address> --function version
```
## Environment Variables
Add RPC URLs and private keys to .env
STARKNET_NETWORK=testnet
STARKNET_PRIVATE_KEY=
RPC_URL= https://starknet-testnet.infura.io/v3/<api-key>

## Post Deployment
- Verify contracts on StarkScan or Voyager
- Publish ABIs in /artifacts
- Update docs with latest addresses
- Announce deployment in changelog/releases.