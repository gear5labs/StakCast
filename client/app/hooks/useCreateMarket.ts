import { useCallback, useEffect, useState } from "react";
import { useContract, useSendTransaction } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "../components/utils/constants";
import { Call, CairoOption, CairoOptionVariant } from "starknet";
import { toast } from "react-toastify";

export interface CreateMarketParams {
  title: string;
  description: string;
  choices: [string, string];
  category: number;
  endTime: number;
  predictionMarketType: number;
  cryptoAsset?: string;
  targetPrice?: number;
}

type CryptoPrediction = {
  cryptoAsset: string;
  targetPrice: number;
}

interface UseCreateMarketReturn {
  createMarket: (params: CreateMarketParams) => Promise<void>;
  loading: boolean;
  error: string | null;
  success: boolean;
  status: string;
}

export const useCreateMarket = (): UseCreateMarketReturn => {
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });

  const [calls, setCalls] = useState<Call[] | undefined>(undefined);
  const [shouldSend, setShouldSend] = useState(false);

  const { send, error, status, isPending, isSuccess } = useSendTransaction({
    calls,
  });

  const createMarket = useCallback(
    async (params: CreateMarketParams): Promise<void> => {
      if (!contract) {
        console.warn("Contract not initialized");
        throw new Error("Contract not initialized");
      }

      try {
        const { title, description, choices, category, endTime, predictionMarketType, cryptoAsset, targetPrice } = params;

        let cryptoPrediction: CryptoPrediction | null;
        if (predictionMarketType === 1 && cryptoAsset && targetPrice) {
          cryptoPrediction = { cryptoAsset, targetPrice };
        } else {
          cryptoPrediction = null
        }

        const populated = await contract.populate("create_predictions", [
          title,
          description,
          {
            '0': choices[0],
            '1': choices[1]
          },
          category,
          endTime,
          predictionMarketType,
          cryptoPrediction ? new CairoOption<CryptoPrediction>(CairoOptionVariant.Some, cryptoPrediction) : new CairoOption<CryptoPrediction>(CairoOptionVariant.None),
        ]);

        setCalls([populated]);
        setShouldSend(true);

        toast.info("Creating market...");
        toast.info("Please approve the transaction with your wallet");
      } catch (err) {
        console.error("Failed to populate create market transaction:", err);
        throw err;
      }

      return Promise.resolve();
    },
    [contract]
  );

  useEffect(() => {
    if (calls && shouldSend) {
      send();
      setShouldSend(false);
    }
  }, [calls, shouldSend, send]);

  useEffect(() => {
    if (isSuccess) {
      toast.success("Market created successfully!");
    }
  }, [isSuccess]);

  useEffect(() => {
    if (error) {
      toast.error(error.message || "Failed to create market");
    }
  }, [error]);

  return {
    createMarket,
    loading: isPending,
    success: isSuccess,
    error: error ? error.message : null,
    status,
  };
}; 