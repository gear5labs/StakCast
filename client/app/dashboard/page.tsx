"use client";

import type React from "react";
import { useState } from "react";
import { TrendingUp, ArrowLeft, DollarSign, Target, Award } from "lucide-react";
import { useAccount} from "@starknet-react/core";

import { StatsCard } from "./(cards)/statsCard";
import { Chart } from "./(components)/chart";
import Disconnected from "./disconnected";
import { useUserPredictions } from "../hooks/useBet";
import ActivePredictions from "./(components)/activepredictions";
// import RecentActivity from "./(components)/recentActivity";
import Claimable from "./(components)/claimable";
import { useIsConnected } from "../hooks/useIsConnected";

type TimeFrame = "7d" | "1m" | "all";

const DashboardPage = () => {
  const { address } = useAccount();
   const connected=useIsConnected();
  const [activeTimeFrame, setActiveTimeFrame] = useState<TimeFrame>("1m");
  const { predictions } = useUserPredictions();
  console.log(predictions)
  const handleGoBack = () => {
    window.history.back();
  };

  const earningsData = {
    "7d": { value: "$0", trend: "+12%", description: "last 7 days" },
    "1m": { value: "$0", trend: "+65%", description: "last month" },
    all: { value: "$0", trend: "+156%", description: "all time" },
  };

  if (!connected) {
    return <Disconnected />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-950 dark:via-slate-900 dark:to-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex items-center gap-4 mb-8">
          <button
            onClick={handleGoBack}
            className="flex items-center justify-center w-10 h-10 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors shadow-sm"
          >
            <ArrowLeft className="w-4 h-4 text-slate-600 dark:text-slate-400" />
          </button>
          <div className="flex-1">
            <h1 className="text-3xl  bg-gradient-to-r from-slate-900 to-slate-600 dark:from-white dark:to-slate-300 bg-clip-text text-transparent">
              Dashboard
            </h1>
            <p className="text-slate-600 dark:text-slate-400 mt-1">
              Welcome back, {address?.slice(0, 6)}...{address?.slice(-4)}
            </p>
          </div>
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 rounded-full text-sm font-medium">
            <div className="w-2 h-2 bg-green-500 rounded-full" />
            Connected
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          {/* Total Earned with Tabs */}
          <div className="relative overflow-hidden bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700">
            <div className="absolute inset-0 bg-gradient-to-br from-white to-slate-50 dark:from-slate-800 dark:to-slate-700" />
            <div className="relative p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="p-2.5 bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl text-white shadow-lg">
                  <DollarSign className="w-5 h-5" />
                </div>
                <div className="flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
                  <TrendingUp className="w-3 h-3" />
                  {earningsData[activeTimeFrame].trend}
                </div>
              </div>

              {/* Time Frame Tabs */}
              <div className="flex bg-slate-100 dark:bg-slate-700 rounded-lg p-1 mb-4">
                {(["7d", "1m", "all"] as TimeFrame[]).map((timeFrame) => (
                  <button
                    key={timeFrame}
                    onClick={() => setActiveTimeFrame(timeFrame)}
                    className={`flex-1 px-3 py-1.5 text-xs font-medium rounded-md transition-all ${
                      activeTimeFrame === timeFrame
                        ? "bg-white dark:bg-slate-600 text-slate-900 dark:text-white shadow-sm"
                        : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                    }`}
                  >
                    {timeFrame === "7d"
                      ? "7 Days"
                      : timeFrame === "1m"
                      ? "1 Month"
                      : "All Time"}
                  </button>
                ))}
              </div>

              <div>
                <p className="text-2xl font-bold text-slate-900 dark:text-white mb-1">
                  {earningsData[activeTimeFrame].value}
                </p>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">
                  Total Earned
                </p>
                <p className="text-xs text-slate-500 dark:text-slate-500 mt-1">
                  {earningsData[activeTimeFrame].description}
                </p>
              </div>
            </div>
          </div>

          <StatsCard
            title="Your Total Bets"
            value={predictions.length.toString()}
            icon={<Target className="w-5 h-5" />}
            trend="+7"
            trendUp={true}
            description=" User Total Active Bets"
          />
          <StatsCard
            title="Win Rate"
            value="65%"
            icon={<Award className="w-5 h-5" />}
            trend="+7.8%"
            trendUp={true}
            description="improvement"
          />
        </div>

        {/* Balance and Portfolio Section */}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-10">
          <ActivePredictions />
          <Claimable />
        </div>
        {/* <BalanceAndPortfolio /> */}

        {/* Chart Section */}
        <Chart />

        {/* Main Content Sections */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Active Predictions */}
          {/* <ActivePredictions /> */}
          {/* Recent Activity */}
          {/* <RecentActivity /> */}
        </div>
        
      </div>
    </div>
  );
};

export default DashboardPage;
