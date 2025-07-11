import { RpcProvider, Contract } from 'starknet';


export const starknetProvider = new RpcProvider({
  nodeUrl: process.env.STARKNET_RPC_URL || 'https://starknet-mainnet.public.blastapi.io',
});


const PREDICTION_HUB_CONTRACT_ADDRESS = process.env.PREDICTION_HUB_CONTRACT_ADDRESS || '0xYOUR_CONTRACT_ADDRESS';
const PREDICTION_HUB_CONTRACT_ABI = require('./predictionHub.abi.json'); 

export const predictionHubContract = new Contract(
  PREDICTION_HUB_CONTRACT_ABI,
  PREDICTION_HUB_CONTRACT_ADDRESS,
  starknetProvider
);
