import { useEffect, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { Market } from "../types";
import { STAKCAST_CONTRACT_ADDRESS } from "../components/utils/constants";

type PredictionCategory = "crypto" | "sports" | "all";

interface UseMarketDataParams {
  category?: PredictionCategory;
}

type CategoryCount = Record<string, number>;

interface UseMarketDataReturn {
  predictions: Market[] | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  category: PredictionCategory;
  counts: CategoryCount;
}

export const useMarketData = (
  params: UseMarketDataParams = {}
): UseMarketDataReturn => {
  const { category = "all" } = params;

  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });

  const [predictions, setPredictions] = useState<Market[] | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [counts, setCounts] = useState<CategoryCount>({
    general: 0,
    crypto: 0,
    sports: 0,
    all: 0,
  });

  const fetchCounts = async () => {
    if (!contract) return [];

    try {
      const [allPredictions, cryptoPredictions, sportsPredictions] =
        await Promise.all([
          contract.get_all_predictions(),
          contract.get_all_crypto_predictions(),
          contract.get_all_sports_predictions(),
        ]);

      const allCount = Array.isArray(allPredictions)
        ? allPredictions.length
        : 0;
      const cryptoCount = Array.isArray(cryptoPredictions)
        ? cryptoPredictions.length
        : 0;
      const sportsCount = Array.isArray(sportsPredictions)
        ? sportsPredictions.length
        : 0;

      // Calculate general count (all - crypto - sports to avoid double counting)
      const generalCount = Math.max(0, allCount - cryptoCount - sportsCount);

      return {
        general: generalCount,
        crypto: cryptoCount,
        sports: sportsCount,
        all: allCount,
      };
    } catch (err) {
      console.error("Error fetching counts:", err);
      return {
        general: 0,
        crypto: 0,
        sports: 0,
        all: 0,
      };
    }
  };

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

      // Fetch and update counts
      const newCounts = await fetchCounts();
      setCounts(newCounts as CategoryCount);
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

            // Fetch and update counts
            const newCounts = await fetchCounts();
            setCounts(newCounts as CategoryCount);
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
          setCounts({});
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
    counts,
  };
};
