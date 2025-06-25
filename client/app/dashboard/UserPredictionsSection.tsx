import React, { useState } from "react";
import { useUserPredictions } from "@/app/hooks/useUserPredictions";
import { Button } from "@/components/ui/button";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "@/app/components/utils/constants";
import { toast } from "react-toastify";
import { formatAmount } from "@/app/utils/utils";

const UserPredictionsSection = () => {
  const { predictions, loading, error, claimableAmount } = useUserPredictions();
  const [filter, setFilter] = useState<"active" | "resolved">("active");
  const [claiming, setClaiming] = useState<string | null>(null);
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });

  const handleCollectWinnings = async (prediction: any) => {
    if (!contract) return;
    setClaiming(prediction.market.market_id.toString());
    try {
      // For each claimable bet, call collect_winnings
      for (const idx of prediction.betIdxs) {
        await contract.collect_winnings(
          prediction.market.market_id,
          prediction.marketType === "regular" ? 0 : prediction.marketType === "crypto" ? 1 : 2,
          idx
        );
      }
      toast.success("Winnings claimed successfully!");
    } catch (err) {
      toast.error("Failed to claim winnings");
    } finally {
      setClaiming(null);
    }
  };

  const filtered = predictions.filter((p) =>
    filter === "active" ? !p.market.is_resolved : p.market.is_resolved
  );

  return (
    <section className="mt-12">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-300 bg-clip-text text-transparent">
          My Predictions
        </h2>
        <div className="flex gap-2">
          <Button
            variant={filter === "active" ? "default" : "outline"}
            onClick={() => setFilter("active")}
          >
            Active
          </Button>
          <Button
            variant={filter === "resolved" ? "default" : "outline"}
            onClick={() => setFilter("resolved")}
          >
            Resolved
          </Button>
        </div>
      </div>
      {/* Claimable Amount Row */}
      <div className="mb-4 flex items-center gap-4">
        <span className="font-semibold text-slate-700 dark:text-slate-200 text-base">Total Claimable Amount:</span>
        <span className="text-lg font-bold text-green-600 dark:text-green-400">{formatAmount(claimableAmount)}</span>
      </div>
      {loading ? (
        <div className="text-center py-8">Loading your predictions...</div>
      ) : error ? (
        <div className="text-center text-red-500 py-8">{error}</div>
      ) : filtered.length === 0 ? (
        <div className="text-center text-slate-500 py-8">
          No {filter} predictions found.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full bg-white dark:bg-slate-900 rounded-xl shadow border border-slate-200 dark:border-slate-700">
            <thead>
              <tr className="text-left text-slate-700 dark:text-slate-200 text-sm">
                <th className="px-4 py-3">Market ID</th>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Your Choices</th>
                <th className="px-4 py-3">Your Staked Amount</th>
                <th className="px-4 py-3">End Time</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((p, idx) => {
                // Sum all user's staked amounts for this market
                const totalStaked = p.userBets.reduce((sum, bet) => {
                  return sum + (bet.stake?.amount ? Number(bet.stake.amount) : 0);
                }, 0);
                // Map user choices to readable labels with amount
                const marketChoices = Object.values(p.market.choices);
                const yesLabel = marketChoices[0]?.label?.toString();
                const noLabel = marketChoices[1]?.label?.toString();
                const userChoices = p.userBets.map((bet) => {
                  let label = bet.choice?.label?.toString();
                  let text = label;
                  if (label === yesLabel) text = "Yes";
                  else if (label === noLabel) text = "No";
                  return `${text} (${formatAmount(bet.stake?.amount || 0)})`;
                }).join(", ");
                return (
                  <tr key={idx} className="border-t border-slate-100 dark:border-slate-800 text-slate-900 dark:text-white text-sm">
                    <td className="px-4 py-3 font-mono">{p.market.market_id.toString()}</td>
                    <td className="px-4 py-3">{p.market.title}</td>
                    <td className="px-4 py-3">{userChoices}</td>
                    <td className="px-4 py-3">{formatAmount(totalStaked)}</td>
                    <td className="px-4 py-3">{formatEndTime(p.market.end_time)}</td>
                    <td className="px-4 py-3">
                      {p.market.is_resolved ? (
                        <span className="px-2 py-1 rounded bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-400">Resolved</span>
                      ) : (
                        <span className="px-2 py-1 rounded bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-400">Active</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {p.market.is_resolved ? (
                        <Button
                          size="sm"
                          disabled={!p.canClaim || claiming === p.market.market_id.toString()}
                          onClick={() => handleCollectWinnings(p)}
                          title={p.canClaim ? "Collect your winnings" : "You have no claimable winnings for this market"}
                        >
                          {claiming === p.market.market_id.toString() ? "Claiming..." : "Collect Winnings"}
                        </Button>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
};

function formatEndTime(endTime: any) {
  const date = new Date(Number(endTime) * 1000);
  return date.toLocaleString();
}

export default UserPredictionsSection; 