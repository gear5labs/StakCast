import { useEffect, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "../components/utils/constants";
import { ChartDataPoint } from "@/app/types";
import { Uint256 } from "starknet";


export const useChartData = (marketId: string) => {
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });

  const [data, setData] = useState<ChartDataPoint[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    if (!contract) return;

    setLoading(true);
    setError(null);

    try {
      const result = await contract.get_market_activity(BigInt(marketId));
      console.log(result);
      if (Array.isArray(result)) {
        setData(
          result.map(
            (item: {
              choice: bigint | Uint256 | number;
              amount: number | Uint256 | bigint;
            }): ChartDataPoint => ({
              choice:
                typeof item.choice === "object" && "low" in item.choice
                  ? BigInt(item.choice.low)
                  : BigInt(item.choice),
              amount:
                typeof item.amount === "object" && "low" in item.amount
                  ? BigInt(item.amount.low)
                  : BigInt(item.amount),
            })
          )
        );
      } else {
        throw new Error("Invalid data format");
      }
    } catch (err) {
      console.error("Error fetching chart data:", err);
      setError(
        err instanceof Error ? err.message : "Failed to fetch chart data"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [contract]);

  return {
    data,
    loading,
    error,
    refetch: fetchData,
  };
};
