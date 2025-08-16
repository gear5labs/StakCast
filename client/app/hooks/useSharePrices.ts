import { useEffect, useMemo, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "@/app/components/utils/constants";
import { normalizeWEI } from "@/app/utils/utils";

export interface SharePricesState {
  priceNoPercent: string; // Option1 (mapped as "No") percent string (e.g., "45.00")
  priceYesPercent: string; // Option2 (mapped as "Yes") percent string (e.g., "55.00")
}

export const useSharePrices = (marketId?: string | number | bigint) => {
  const { contract } = useContract({ abi, address: STAKCAST_CONTRACT_ADDRESS as "0x" });

  const [prices, setPrices] = useState<SharePricesState>({ priceNoPercent: "0.00", priceYesPercent: "0.00" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const fetchPrices = async () => {
      if (!contract || marketId === undefined || marketId === null) return;
      try {
        setLoading(true);
        setError(null);

       
        const result = await contract.calculate_share_prices(BigInt(marketId));


        const [rawA, rawB] = Array.isArray(result) ? result : [undefined, undefined];

        const priceA = BigInt(rawA as unknown as bigint); // Option 1 (No)
        const priceB = BigInt(rawB as unknown as bigint); // Option 2 (Yes)

        // Convert to percentage strings with 2 decimals
        const percentA = (parseFloat(normalizeWEI(priceA)) * 100).toFixed(2);
        const percentB = (parseFloat(normalizeWEI(priceB)) * 100).toFixed(2);

        if (isMounted) {
          setPrices({ priceNoPercent: percentA, priceYesPercent: percentB });
        }
      } catch (err) {
        if (isMounted) {
          setError(err instanceof Error ? err.message : "Failed to fetch share prices");
          setPrices({ priceNoPercent: "0.00", priceYesPercent: "0.00" });
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    fetchPrices();

    return () => {
      isMounted = false;
    };
  }, [contract, marketId]);

  const value = useMemo(() => ({ ...prices, loading, error }), [prices, loading, error]);
  return value;
};
