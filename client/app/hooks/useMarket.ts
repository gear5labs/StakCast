import { useEffect, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { Market } from "../types";

type PredictionCategory = "crypto" | "sports" | "all";

interface UseMarketDataParams {
  category?: PredictionCategory;
}

interface UseMarketDataReturn {
  predictions: Market[] | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  category: PredictionCategory;
}

const contractAddress =
  "0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534";

export const useMarketData = (
  params: UseMarketDataParams = {}
): UseMarketDataReturn => {
  const { category = "all" } = params;

  const { contract } = useContract({
    abi,
    address: contractAddress as "0x",
  });

  const [predictions, setPredictions] = useState<Market[] | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPredictions = async () => {
    if (!contract) return;

    try {
      setLoading(true);
      setError(null);

      let result;

      switch (category) {
        case "crypto":
          result = await contract.get_all_crypto_predictions();
          break;
        case "sports":
          result = await contract.get_all_sports_predictions();
          break;
        case "all":
        default:
          result = await contract.get_all_predictions();
          break;
      }

      console.log(`${category} predictions:`, result);
      setPredictions(result as unknown as Market[]);
    } catch (err) {
      console.error(`Error fetching ${category} predictions:`, err);
      setError(
        err instanceof Error
          ? err.message
          : `Failed to fetch ${category} predictions`
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let isMounted = true;

    const load = async () => {
      try {
        setLoading(true);
        setError(null);

        if (!contract) return;

        let result;
        switch (category) {
          case "crypto":
            result = await contract.get_all_crypto_predictions();
            break;
          case "sports":
            result = await contract.get_all_sports_predictions();
            break;
          case "all":
          default:
            result = await contract.get_all_predictions();
            break;
        }

        console.log(`${category} predictions:`, result);

        if (isMounted) {
          if (Array.isArray(result)) {
            setPredictions(result as unknown as Market[]);
          } else {
            throw new Error("Invalid response format");
          }
        }
      } catch (err) {
        if (isMounted) {
          setError(
            err instanceof Error ? err.message : "Failed to fetch predictions"
          );
          setPredictions(null);
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    load();

    return () => {
      isMounted = false;
    };
  }, [contract, category]);

  return {
    predictions,
    loading,
    error,
    refetch: fetchPredictions,
    category,
  };
};
