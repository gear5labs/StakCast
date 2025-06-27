import { useEffect, useState } from "react";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "@/app/components/utils/constants";
import { useAppContext } from "@/app/context/appContext";

import { Uint256 } from "starknet";

export interface MarketChoices {
  [key: number]: { label: string | bigint | number; id: number };
  0: { label: string | bigint | number; id: number };
  1: { label: string | bigint | number; id: number };
}
export interface AugmentedMarket {
  market_id: number;
  category: string;
  end_time: number;
  title: string;
  description: string;
  choices: MarketChoices;
  is_resolved: boolean;
  winning_choice?: { Some: number | undefined };
  total_pool: number;
  marketType: "regular" | "crypto" | "sports";
  is_open: boolean;
  image_url: string;
}

export interface UserPrediction {
  market: AugmentedMarket;
  marketType: "regular" | "crypto" | "sports";
  userBets: UserBet[];
  canClaim: boolean;
  isWinner: boolean;
  betIdxs: number[];
}

export interface UserBet {
  choice: {
    label: bigint | string | number;
    staked_amount: bigint | number | Uint256;
  };
  stake: {
    amount: bigint | number | Uint256;
    claimed?: boolean;
  };
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
        console.log(regular);
        const all: AugmentedMarket[] = [
          ...(regular || []).map((m) => ({
            ...m,
            marketType: "regular" as const,
            market_id: Number(m.market_id),
            category: m.category.toString(),
            end_time: Number(m.end_time),
            choices: m.choices as MarketChoices,

            winning_choice: m.winning_choice?.Some
              ? { Some: Number(m.winning_choice.Some.label) }
              : undefined,
            total_pool: Number(m.total_pool),
          })),

          ...(crypto || []).map((m) => ({
            ...m,
            marketType: "crypto" as const,
            market_id: Number(m.market_id),
            category: m.category.toString(),
            end_time: Number(m.end_time),
            choices: m.choices as MarketChoices,

            winning_choice: m.winning_choice?.Some
              ? { Some: Number(m.winning_choice.Some.label) }
              : undefined,
            total_pool: Number(m.total_pool),
          })),
          ...(sports || []).map((m) => ({
            ...m,
            marketType: "sports" as const,
            market_id: Number(m.market_id),
            category: m.category.toString(),
            end_time: Number(m.end_time),
            choices: m.choices as MarketChoices,
            winning_choice: m.winning_choice?.Some
              ? { Some: Number(m.winning_choice.Some.label) }
              : undefined,
            total_pool: Number(m.total_pool),
          })),
        ];
        // For each prediction, fetch user bets and claimable status

        let resolvedCount = 0;
        let winCount = 0;
        const userPredictions: UserPrediction[] = await Promise.all(
          all.map(async (market: AugmentedMarket) => {
            const marketType: "regular" | "crypto" | "sports" =
              market.marketType;
            // Get bet count
            let betCount: bigint | number = 0;
            try {
              betCount = await contract.get_bet_count_for_market(
                address,
                Number(market.market_id),
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
                  Number(market.market_id),
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
                    Number(market.choices[market.winning_choice.Some]?.label)
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
        console.error(err);
        setError("Failed to fetch user predictions");
      } finally {
        setLoading(false);
      }
    };
    fetchPredictions();
  }, [contract, address]);

  return { predictions, loading, error, claimableAmount, winRate };
};
