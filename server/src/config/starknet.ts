import { RpcProvider, Contract } from 'starknet';

// Configure your Starknet RPC endpoint here
export const starknetProvider = new RpcProvider({
  nodeUrl: process.env.STARKNET_RPC_URL || 'https://starknet-mainnet.public.blastapi.io',
});

// Replace with your actual contract address and ABI
const PREDICTION_HUB_CONTRACT_ADDRESS = process.env.PREDICTION_HUB_CONTRACT_ADDRESS || '0xYOUR_CONTRACT_ADDRESS';
const PREDICTION_HUB_CONTRACT_ABI = require('./predictionHub.abi.json'); // Place your ABI JSON in the same directory

export const predictionHubContract = new Contract(
  PREDICTION_HUB_CONTRACT_ABI,
  PREDICTION_HUB_CONTRACT_ADDRESS,
  starknetProvider
);
