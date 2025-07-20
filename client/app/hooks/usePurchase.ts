import { useCallback, useEffect, useState } from "react";
import { useContract, useSendTransaction } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import {
  SKTokenAddress,
  STAKCAST_CONTRACT_ADDRESS,
  STRKTokenAddress,
} from "../components/utils/constants";
import erc20Abi from "../abis/token";
import { cairo, Call } from "starknet";
import { useAppContext } from "../context/appContext";
import { toast } from "react-toastify";
interface UsePurchaseReturn {
  placeBet: (
    market_id: number | bigint,
    choice_idx: number,
    amount: bigint | number,
  
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
  const { selectedToken } = useAppContext();
  const { contract: ercContract } = useContract({
    abi: erc20Abi,
    address:
      selectedToken == "SK" ? (SKTokenAddress as "0x") : STRKTokenAddress,
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
      amount: bigint | number
    ): Promise<void> => {
      if (!contract) {
        console.warn("Contract not initialized");
        return Promise.resolve();
      }
      if (!ercContract) {
        console.warn("Contract not initialized");
        return Promise.resolve();
      }
      try {
        const tokenApproval = await ercContract.populate("approve", [
          STAKCAST_CONTRACT_ADDRESS,
          cairo.uint256(amount),
        ]);

        await contract.populate("buy_shares", [
          BigInt(market_id),
          BigInt(choice_idx),
          amount,
        ]);
        const populated =
          selectedToken == "SK"
            ? await contract.populate("buy_shares", [
                BigInt(market_id),
                BigInt(choice_idx),
                amount,
              ])
            : await contract.populate("buy_shares", [
                BigInt(market_id),
                BigInt(choice_idx),
                amount,
              ]);

        setCalls([tokenApproval, populated]);

        setShouldSend(true);
        toast.info(
          ` staked ${choice_idx == 0 ? "NO" : "Yes"} at ${
            Number(amount) / 10 ** 18
          }${selectedToken}`
        );
        toast.info("please approve the transaction with your wallet");
      } catch (err) {
        console.error("Failed to populate transaction:", err);
        toast.error(
          typeof err == "string" ? err : "failed to initiate transaction"
        );
      }

      return Promise.resolve();
    },
    [contract, selectedToken, ercContract]
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
