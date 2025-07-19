"use client";
import React, { useState } from "react";
import { UserPrediction, useUserPredictions } from "@/app/hooks/useBet";
import { Button } from "@/components/ui/button";
import { useContract } from "@starknet-react/core";
import abi from "@/app/abis/abi";
import { STAKCAST_CONTRACT_ADDRESS } from "@/app/components/utils/constants";
import { toast } from "react-toastify";
import { formatAmount } from "@/app/utils/utils";
import { Table } from "@/app/components/shared/table";
import { TrendingUp, Clock, Award, Filter, Wallet } from "lucide-react";
import { useIsConnected } from "@/app/hooks/useIsConnected";
import Header from "@/app/components/layout/Header";
import SkeletonLoader from "@/app/components/ui/loading/skeletonLoader";
import { BackButton } from "@/app/components/ui/backButton";
import ErrorPage from "./(components)/error";

// interface Stake {
//   amount: string;
// }

// interface Bet {
//   choice: {
//     label: bigint | number;
//     stake: Stake;
//   };
//   stake: Stake;
// }

const UserPredictionsSection = () => {
  const { predictions, loading, error } = useUserPredictions();
  const [filter, setFilter] = useState<"active" | "resolved">("active");
  const [claiming, setClaiming] = useState<string | null>(null);
  const isConnected = useIsConnected();
  const { contract } = useContract({
    abi,
    address: STAKCAST_CONTRACT_ADDRESS as "0x",
  });

  const handleCollectWinnings = async (prediction: UserPrediction) => {
    if (!contract) return;
    setClaiming(prediction.market.market_id.toString());
    try {
      for (const idx of prediction.betIdxs) {
        await contract.collect_winnings(
          Number(prediction.market.market_id),
          prediction.marketType === "regular"
            ? 0
            : prediction.marketType === "crypto"
            ? 1
            : 2,
          idx
        );
      }
      toast.success("Winnings claimed successfully!");
    } catch (ex) {
      console.log(ex);
      toast.error("Failed to claim winnings");
    } finally {
      setClaiming(null);
    }
  };

  const filtered = predictions.filter((p) =>
    filter === "active" ? !p.market.is_resolved : p.market.is_resolved
  );

  // const totalStaked = predictions.reduce(
  //   (sum, p) =>
  //     sum +
  //     p.userBets.reduce(
  //       (betSum, bet) =>
  //         betSum + (bet.stake?.amount ? Number(bet.stake.amount) : 0),
  //       0
  //     ),
  //   0
  // );

  const activePredictions = predictions.filter(
    (p) => !p.market.is_resolved
  ).length;
  const resolvedPredictions = predictions.filter(
    (p) => p.market.is_resolved
  ).length;

  const columns = [
    {
      header: "Market",
      accessor: (p: UserPrediction) => (
        <div className="flex flex-col gap-1">
          <span className="font-medium text-slate-900 dark:text-white">
            {p.market.title}
          </span>
          <span className="text-xs text-slate-500 dark:text-slate-400 font-mono">
            ID: {p.market.market_id.toString()}
          </span>
        </div>
      ),
    },
    {
      header: "Your Positions",
      accessor: (p: UserPrediction) => {
        const marketChoices = Object.values(p.market.choices);
        const yesLabel = marketChoices[0]?.label?.toString();
        const noLabel = marketChoices[1]?.label?.toString();

        return (
          <div className="flex flex-wrap items-center gap-2">
            {p.userBets.map((bet, idx) => {
              const label = bet.choice?.label?.toString();
              let text = label;
              let colorClass =
                "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200";

              if (label === yesLabel) {
                text = "Yes";
                colorClass =
                  "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200";
              } else if (label === noLabel) {
                text = "No";
                colorClass =
                  "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200";
              }

              return (
                <span
                  key={idx}
                  className={`flex px-2 py-1 rounded-full text-xs font-medium ${colorClass}`}
                >
                  {text}{" "}
                  <span className="ml-1 font-semibold">
                    {formatAmount(
                      (bet.stake?.amount as unknown as string) || "0"
                    )}
                  </span>
                  {idx < p.userBets.length - 1 && (
                    <span className="mx-1 text-slate-400 dark:text-slate-500">
                      ,
                    </span>
                  )}
                </span>
              );
            })}
          </div>
        );
      },
    },
    {
      header: "Total Staked",
      accessor: (p: UserPrediction) => (
        <div className="flex items-center gap-2">
          <Wallet className="w-4 h-4 text-slate-500" />
          <span className="font-semibold text-slate-900 dark:text-white">
            {formatAmount(
              p.userBets
                .reduce(
                  (sum, bet) =>
                    sum + (bet.stake?.amount ? Number(bet.stake.amount) : 0),
                  0
                )
                .toString()
            ).toString()}
          </span>
        </div>
      ),
    },

    {
      header: "End Time",
      accessor: (p: UserPrediction) => (
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-slate-500" />
          <span className="text-sm text-slate-600 dark:text-slate-300">
            {formatEndTime(p.market.end_time)}
          </span>
        </div>
      ),
    },
    {
      header: "Status",
      accessor: (
        p: UserPrediction // Change `p` type to UserPrediction
      ) =>
        p.market.is_resolved ? (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 text-sm font-medium">
            <Award className="w-3 h-3" />
            Resolved
          </span>
        ) : (
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-amber-100 dark:bg-amber-900 text-amber-700 dark:text-amber-300 text-sm font-medium">
            <TrendingUp className="w-3 h-3" />
            Active
          </span>
        ),
    },
    {
      header: "Action",
      accessor: (p: UserPrediction) =>
        p.market.is_resolved ? (
          <Button
            size="sm"
            disabled={!p.canClaim || claiming === p.market.market_id.toString()}
            onClick={() => handleCollectWinnings(p)}
            className={`${
              p.canClaim
                ? "bg-green-600 hover:bg-green-700 text-white"
                : "bg-slate-200 text-slate-500 cursor-not-allowed"
            }`}
            title={
              p.canClaim
                ? "Collect your winnings"
                : "You have no claimable winnings for this market"
            }
          >
            {claiming === p.market.market_id.toString() ? (
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                Claiming...
              </div>
            ) : (
              <div className="flex items-center gap-1">
                <Award className="w-3 h-3" />
                Collect
              </div>
            )}
          </Button>
        ) : (
          <span className="text-slate-400 text-sm">Pending</span>
        ),
    },
  ];

  if (loading) {
    return <SkeletonLoader />;
  }

  if (error) {
    return <ErrorPage error={error} />;
  }

  if (!isConnected)
    return (
      <>
        <div className="mx-0 ">Connect wallet to continue</div>
      </>
    );

  return (
    <>
      <Header />

      <section className="mt-12 p-7">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
          <div>
            <BackButton />
            <h2 className="text-2xl p-5 font-bold bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-300 bg-clip-text text-transparent">
              My Predictions
            </h2>
            <p className="text-slate-600 dark:text-slate-400 mt-1">
              Track your bets and collect winnings
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-slate-500" />
            <Button
              variant={filter === "active" ? "default" : "outline"}
              onClick={() => setFilter("active")}
              className="flex items-center gap-2"
            >
              <TrendingUp className="w-4 h-4" />
              Active ({activePredictions})
            </Button>
            <Button
              variant={filter === "resolved" ? "default" : "outline"}
              onClick={() => setFilter("resolved")}
              className="flex items-center gap-2"
            >
              <Award className="w-4 h-4" />
              Resolved ({resolvedPredictions})
            </Button>
          </div>
        </div>

        {/* Stats Cards */}
        {/* <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
          <DashboardCard
            title="Total Staked"
            icon={<TrendingUp />}
            description="Total Staked Tokens"
          >
            <div className="flex items-center gap-4 p-3 rounded-xl dark:bg-green-900/10">
              <div>
                <p className="text-xl sm:text-2xl font-semibold text-blue-800 dark:text-green-100">
                  {formatAmount(totalStaked.toString())}
                </p>
              </div>
            </div>
          </DashboardCard>

          <DashboardCard
            title="Claimable"
            icon={<Award />}
            description="your claimable amount"
          >
            <div className="flex items-center gap-4 p-3 rounded-xl dark:bg-green-900/10">
              <div>
                <p className="text-xl sm:text-2xl font-semibold text-green-800 dark:text-green-100">
                  {formatAmount(claimableAmount)}
                </p>
              </div>
            </div>
          </DashboardCard>

          <DashboardCard
            title="Total Bets"
            description="Total number of bets placed"
            icon={<Wallet />}
          >
            <div className="flex items-center gap-4 p-3 rounded-xl dark:bg-green-900/10">
              <div>
                <p className="text-xl sm:text-2xl font-semibold text-purple-600 dark:text-green-100">
                  {predictions.length}
                </p>
              </div>
            </div>
          </DashboardCard>
        </div> */}

        {/* Table */}
        {filtered.length === 0 ? (
          <div className="bg-slate-50 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-700 rounded-xl p-12 text-center">
            <div className="w-16 h-16 bg-slate-200 dark:bg-slate-700 rounded-full flex items-center justify-center mx-auto mb-4">
              {filter === "active" ? (
                <TrendingUp className="w-8 h-8 text-slate-500" />
              ) : (
                <Award className="w-8 h-8 text-slate-500" />
              )}
            </div>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2">
              No {filter} predictions found
            </h3>
            <p className="text-slate-500 dark:text-slate-400">
              {filter === "active"
                ? "You don't have any active predictions yet. Start betting to see them here!"
                : "You don't have any resolved predictions yet. Check back once your bets are settled."}
            </p>
          </div>
        ) : (
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden">
            <Table
              data={filtered}
              columns={columns}
              keyExtractor={(p) => p.market.market_id.toString()}
            />
          </div>
        )}
      </section>
    </>
  );
};

function formatEndTime(endTime: number) {
  const date = new Date(Number(endTime) * 1000);
  return date.toLocaleString();
}

export default UserPredictionsSection;
