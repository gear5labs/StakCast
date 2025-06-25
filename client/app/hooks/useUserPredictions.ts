import { useEffect, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "@/app/components/utils/constants";
import { useAppContext } from "@/app/context/appContext";
import { Market } from "@/app/types";

export interface UserPrediction {
  market: Market;
  marketType: "regular" | "crypto" | "sports";
  userBets: any[];
  canClaim: boolean;
  isWinner: boolean;
  betIdxs: number[];
}

export const useUserPredictions = () => {
  const { address } = useAppContext();
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });
  const [predictions, setPredictions] = useState<UserPrediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [claimableAmount, setClaimableAmount] = useState<string | bigint>("0");
  const [winRate, setWinRate] = useState<string>("0%");

  useEffect(() => {
    const fetchPredictions = async () => {
      if (!contract || !address) return;
      setLoading(true);
      setError(null);
      try {
        // Fetch all user predictions
        const [regular, crypto, sports, claimable] = await Promise.all([
          contract.get_user_predictions(address),
          contract.get_user_crypto_predictions(address),
          contract.get_user_sports_predictions(address),
          contract.get_user_claimable_amount(address),
        ]);
        setClaimableAmount(claimable?.toString() || "0");
        const all = [
          ...(regular || []).map((m: any) => ({ ...m, marketType: "regular" })),
          ...(crypto || []).map((m: any) => ({ ...m, marketType: "crypto" })),
          ...(sports || []).map((m: any) => ({ ...m, marketType: "sports" })),
        ];
        // For each prediction, fetch user bets and claimable status
        let resolvedCount = 0;
        let winCount = 0;
        const userPredictions: UserPrediction[] = await Promise.all(
          all.map(async (market: any) => {
            const marketType = market.marketType;
            // Get bet count
            let betCount = 0;
            try {
              betCount = await contract.get_bet_count_for_market(
                address,
                market.market_id,
                marketType === "regular" ? 0 : marketType === "crypto" ? 1 : 2
              );
            } catch {}
            // For each bet, get bet details
            const userBets = [];
            const betIdxs = [];
            let canClaim = false;
            let isWinner = false;
            let userWon = false;
            for (let i = 0; i < betCount; i++) {
              try {
                const bet = await contract.get_choice_and_bet(
                  address,
                  market.market_id,
                  marketType === "regular"
                    ? 0
                    : marketType === "crypto"
                    ? 1
                    : 2,
                  i
                );
                userBets.push(bet);
                betIdxs.push(i);
                // Check if resolved, not claimed, and user is winner
                if (
                  market.is_resolved &&
                  !bet.stake.claimed &&
                  market.winning_choice?.Some !== undefined &&
                  bet.choice.label ===
                    market.choices[market.winning_choice.Some]?.label
                ) {
                  canClaim = true;
                  isWinner = true;
                }
                // For win rate: did user win this bet?
                if (
                  market.is_resolved &&
                  market.winning_choice?.Some !== undefined &&
                  bet.choice.label ===
                    market.choices[market.winning_choice.Some]?.label
                ) {
                  userWon = true;
                }
              } catch {}
            }
            // For win rate: count resolved markets the user participated in
            if (market.is_resolved && betCount > 0) {
              resolvedCount++;
              if (userWon) winCount++;
            }
            return {
              market,
              marketType,
              userBets,
              canClaim,
              isWinner,
              betIdxs,
            };
          })
        );
        setPredictions(userPredictions);
        // Calculate win rate
        const rate =
          resolvedCount > 0 ? Math.round((winCount / resolvedCount) * 100) : 0;
        setWinRate(`${rate}%`);
      } catch (err) {
        setError("Failed to fetch user predictions");
      } finally {
        setLoading(false);
      }
    };
    fetchPredictions();
  }, [contract, address]);

  return { predictions, loading, error, claimableAmount, winRate };
};
