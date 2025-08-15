import { useState, useEffect } from 'react';
import { Contract, RpcProvider } from 'starknet';
import PredictionHubABI from '../../abi/PredictionHub.json';

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";
const RPC_URL = process.env.NEXT_PUBLIC_RPC_URL;

// Demo/fallback constants
const DEMO_TVL = '150000';
const DEMO_TOTAL_MARKETS = 3;

export interface Market {
  market_id: string;
  title: string;
  description: string;
  total_pool: string;
  is_open: boolean;
  end_time: number;
  category?: string;
}

// Add wallet hook
export const useWallet = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [address, setAddress] = useState<string | null>(null);
  // const [connecting, setConnecting] = useState(false);


  const disconnectWallet = () => {
    setIsConnected(false);
    setAddress(null);
  };

  return { isConnected, address,  disconnectWallet };
};

export const useContract = () => {
  const [contract, setContract] = useState<Contract | null>(null);
  const [provider, setProvider] = useState<RpcProvider | null>(null);

  useEffect(() => {
    const initContract = async () => {
      try {
        if (!CONTRACT_ADDRESS) {
          throw new Error('CONTRACT_ADDRESS is not defined');
        }
        if (!RPC_URL) {
          throw new Error('RPC_URL is not defined');
        }
        const rpcProvider = new RpcProvider({ nodeUrl: RPC_URL });
        const contractInstance = new Contract(PredictionHubABI, CONTRACT_ADDRESS, rpcProvider);
        
        setProvider(rpcProvider);
        setContract(contractInstance);
        console.log('Contract initialized successfully');
      } catch (error) {
        console.error('Failed to initialize contract:', error);
        setContract(null);
      }
    };

    initContract();
  }, []);

  return { contract, provider };
};

export const useMarkets = () => {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [tvl, setTvl] = useState<string>('0');
  const [totalMarkets, setTotalMarkets] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { contract } = useContract();

  useEffect(() => {
    const fetchMarkets = async () => {
      if (!contract) return;

      try {
        setLoading(true);
        console.log('Attempting to fetch real contract data...');
        
        try {

          const predictionCount = await contract.get_prediction_count();
          const openMarkets = await contract.get_all_open_markets();
          const totalValueLocked = await contract.get_total_value_locked();
          
          const processedMarkets = openMarkets.slice(0, 3).map((market: Market, index: number) => ({
            market_id: market.market_id?.toString() || index.toString(),
            title: market.title || `Market ${index + 1}`,
            description: market.description || "No description available",
            total_pool: market.total_pool?.toString() || "0",
            is_open: market.is_open !== undefined ? market.is_open : true,
            end_time: Number(market.end_time) || Date.now() + 86400000,
            category: market.category || "General"
          }));

          setMarkets(processedMarkets);
          setTvl((Number(totalValueLocked) / 1e18).toFixed(2));
          setTotalMarkets(Number(predictionCount));
          setError(null);
          console.log('Real contract data loaded successfully');
          
        } catch (contractError) {
          console.warn('Contract call failed, using mock data:', contractError);
          
          // Fallback to enhanced mock data
          const mockMarkets: Market[] = [
            {
              market_id: "1",
              title: "Will Bitcoin reach $100,000 by end of 2024?",
              description: "Prediction on Bitcoin price reaching $100k",
              total_pool: "50000000000000000000",
              is_open: true,
              end_time: Date.now() + 86400000,
              category: "Crypto"
            },
            {
              market_id: "2", 
              title: "Will Ethereum upgrade succeed this quarter?",
              description: "Prediction on ETH upgrade success",
              total_pool: "25000000000000000000",
              is_open: true,
              end_time: Date.now() + 172800000,
              category: "Crypto"
            },
            {
              market_id: "3",
              title: "Will StarkNet TVL exceed $1B in 2024?", 
              description: "Prediction on StarkNet ecosystem growth",
              total_pool: "75000000000000000000",
              is_open: true,
              end_time: Date.now() + 259200000,
              category: "DeFi"
            }
          ];

          setMarkets(mockMarkets);
          setTvl(DEMO_TVL);
          setTotalMarkets(DEMO_TOTAL_MARKETS);
          setError("Demo Mode - Contract integration in progress");
        }
        
      } catch (err) {
        console.error('Error in fetchMarkets:', err);
        setError('Failed to load market data');
      } finally {
        setLoading(false);
      }
    };

    const timer = setTimeout(fetchMarkets, 1000);
    return () => clearTimeout(timer);
  }, [contract]);

  return { markets, tvl, totalMarkets, loading, error };
};