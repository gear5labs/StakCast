import { useCallback, useEffect, useState } from "react";
import { useContract, useSendTransaction } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "../components/utils/constants";
import erc20Abi from "../abis/token";
import { cairo, Call, uint256 } from "starknet";

interface UsePurchaseReturn {
  placeBet: (
    market_id: number | bigint,
    choice_idx: number,
    amount: bigint| number,
    market_type: number
  ) => Promise<void>;
  send: ReturnType<typeof useSendTransaction>["send"];
  loading: boolean;
  error: string | null;
  success: boolean;
  status: string;
}

export const usePurchase = (): UsePurchaseReturn => {
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });
  const { contract: ercContract } = useContract({
    abi: erc20Abi,
    address:
      "0x0620e07581e4b797d2dbe6f1ef507899cdd186cc19a96791ac18335a17359c4f",
  });

  const [calls, setCalls] = useState<Call[] | undefined>(undefined);
  const [shouldSend, setShouldSend] = useState(false);

  const { send, error, status, isPending, isSuccess } = useSendTransaction({
    calls,
  });

  const placeBet = useCallback(
    async (
      market_id: number | bigint,
      choice_idx: number,
      amount: bigint| number,
      market_type: number
    ): Promise<void> => {
      if (!contract) {
        console.warn("Contract not initialized");
        return Promise.resolve();
      }
      if (!ercContract) {
        console.warn("Contract not initialized");
        return Promise.resolve();
      }
      console.log(uint256.bnToUint256(11));
      try {
        const tokenApproval = await ercContract.populate("approve", [
          STAKCAST_CONTRACT_ADDRESS,
          cairo.uint256(amount),
        ]);
        const populated = await contract.populate("place_bet", [
          BigInt(market_id),
          BigInt(choice_idx),
          amount,
          BigInt(market_type),
        ]);

        setCalls([tokenApproval, populated]);
        setShouldSend(true);
      } catch (err) {
        console.error("Failed to populate transaction:", err);
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

  return {
    placeBet,
    send,
    loading: isPending,
    success: isSuccess,
    error: error ? error.message : null,
    status,
  };
};
