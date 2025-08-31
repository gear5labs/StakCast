Integration Guide for Stakcast

This guide explains how external developers can interact with the Stakcast protocol.

---

## Contract ABIs and addresses
- **Testnet**: [To be updated after deployment]
- **Mainnet**: [To be updated after deployment]
- **ABIs**: Found in published in releases.

## Typical Workflow
1. **Deposit tokens**
2. **Withdraw tokens**
3. **Claim rewards**
4. **Stake into pools**

---

## Example
```ts
import {Account, Provider,Contract} from "starknet";
import abi from "./Starkcast.json";

//Setup
const provider = new Provider {{sequencer:{network:"testnet"}}};
const account= new Account(provider,"<public-key>","<private-key>");
const contract= new Contract(abi,"<contract-address>",provider);

//Deposit
await contract.connect(account).deposit(1000);

//Stake
await contract.connect(account).stake(500);

//Claim rewards
const rewards =await contract.call("claim_rewards");
console.log("Rewards:",rewards);

//Wthdraw
await contract.connect(account).withdraw(500);
---

## Events
Listen to onchain events to track protocol activity:
- Deposit(address user, uint256 amount)
- Stake(address user, uint256 amount)
- Withdraw(address user, uint256 amount)
- RewardClaimed(address user, uint256 amount)

## Error Handling
- InsufficientBalance- when user tries to withdraw/stake more than deposited
- Paused - protocol is temporarily paused
- Unauthorized- functions which are restricted to govern

## Tips for Integrators
- Always check paused state before calling core functions.
- Use events logs for off-chain indexing
- Never hardcore contract addressses- import them from addresses.json


