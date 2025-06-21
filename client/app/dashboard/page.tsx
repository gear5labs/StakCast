"use client";

import type React from "react";
import { useState } from "react";
import {
  Wallet,
  TrendingUp,
  PlusCircle,
  History,
  ArrowLeft,
  Activity,
  DollarSign,
  Target,
  Award,
  PieChart,
} from "lucide-react";
import { useAccount } from "@starknet-react/core";
import { useAppContext } from "../context/appContext";
import { useMarketData } from "../hooks/useMarket";

import { DashboardCard } from "./dashboardCard";
import { StatsCard } from "./statsCard";
import { Chart } from "./chart";
import Disconnected from "./disconnected";

type TimeFrame = "7d" | "1m" | "all";

const DashboardPage = () => {
  const { address } = useAccount();
  const { status, balanceInUSD: balance, skPrice } = useAppContext();
  const { counts } = useMarketData();
  const [activeTimeFrame, setActiveTimeFrame] = useState<TimeFrame>("1m");

  const handleGoBack = () => {
    window.history.back();
  };

  // Mock data for different timeframes
  const earningsData = {
    "7d": { value: "$0", trend: "+12%", description: "last 7 days" },
    "1m": { value: "$0", trend: "+65%", description: "last month" },
    all: { value: "$0", trend: "+156%", description: "all time" },
  };

  if (status !== "connected") {
    return <Disconnected />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 dark:from-slate-950 dark:via-slate-900 dark:to-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header with Back Button */}
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
            title="Active Markets"
            value={counts.all.toString()}
            icon={<Target className="w-5 h-5" />}
            trend="+7"
            trendUp={true}
            description="Active markets"
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
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* Wallet Balances */}
          <div className="lg:col-span-2 relative overflow-hidden bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-purple-600/5" />
            <div className="relative p-6">
              <div className="flex items-center gap-3 mb-6">
                <div className="p-2 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg">
                  <Wallet className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                    Wallet Balances
                  </h3>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    Your token holdings
                  </p>
                </div>
              </div>

              {/* Token Balances */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                <div className="bg-slate-50 dark:bg-slate-700/50 rounded-xl p-4">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-8 h-8 bg-gradient-to-br from-orange-400 to-orange-600 rounded-full flex items-center justify-center">
                      <span className="text-white text-xs font-bold">SK</span>
                    </div>
                    <div>
                      <p className="font-semibold text-slate-900 dark:text-white">
                        SK Balance
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        StarkNet Token
                      </p>
                    </div>
                  </div>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {`${skPrice?.toFixed(2)} SK` || "0.00"}
                  </p>
                </div>

                <div className="bg-slate-50 dark:bg-slate-700/50 rounded-xl p-4">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-8 h-8 bg-gradient-to-br from-purple-400 to-purple-600 rounded-full flex items-center justify-center">
                      <span className="text-white text-xs font-bold">ST</span>
                    </div>
                    <div>
                      <p className="font-semibold text-slate-900 dark:text-white">
                        STRK Balance
                      </p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        Starknet Token
                      </p>
                    </div>
                  </div>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">
                    {balance || "0.00"}
                  </p>
                </div>
              </div>

              <div className="space-y-3">
                <p className="text-sm text-slate-600 dark:text-slate-400 mb-3">
                  Available Rewards:{" "}
                  <span className="font-semibold text-green-600">
                    $1,255.68
                  </span>
                </p>
                <div className="flex gap-3">
                  <div className="flex-1 relative group">
                    <button className="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                      Withdraw Tokens
                    </button>
                    <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-slate-900 text-white text-xs rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap">
                      Transfer tokens to external wallet
                    </div>
                  </div>
                  <div className="flex-1 relative group">
                    <button className="w-full border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 font-medium py-3 px-4 rounded-lg transition-colors">
                      Claim Rewards
                    </button>
                    <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-slate-900 text-white text-xs rounded-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap">
                      Add earned rewards to balance
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg">
                  <PieChart className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                    Portfolio
                  </h3>
                  <p className="text-sm text-slate-600 dark:text-slate-400">
                    Asset allocation
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                      SK Token
                    </span>
                  </div>
                  <span className="text-sm font-semibold text-slate-900 dark:text-white">
                    50%
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-purple-500 rounded-full"></div>
                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                      STRK Token
                    </span>
                  </div>
                  <span className="text-sm font-semibold text-slate-900 dark:text-white">
                    50%
                  </span>
                </div>

                {/* Portfolio Value */}
                <div className="pt-4 border-t border-slate-200 dark:border-slate-700">
                  <p className="text-sm text-slate-600 dark:text-slate-400 mb-1">
                    Total Portfolio Value
                  </p>
                  <p className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
                    ${(Number.parseFloat(balance || "0") * 2 || 0).toFixed(2)}
                  </p>
                  <p className="text-xs text-green-600 dark:text-green-400 mt-1">
                    +12.5% today
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Chart Section */}
        <Chart />

        {/* Main Content Sections */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Active Predictions */}
          <DashboardCard
            title="Active Predictions"
            description="Your current market positions"
            icon={<Target className="w-5 h-5" />}
            iconBg="from-blue-500 to-purple-600"
          >
            <div className="flex flex-col items-center justify-center py-12">
              <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-purple-100 dark:from-blue-900/30 dark:to-purple-900/30 rounded-full flex items-center justify-center mb-4">
                <History className="w-8 h-8 text-blue-600 dark:text-blue-400" />
              </div>
              <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
                No Active Predictions
              </h3>
              <p className="text-slate-500 dark:text-slate-400 text-center mb-4">
                Start making predictions to see them here
              </p>
              <button className="flex items-center gap-2 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-lg transition-colors text-sm font-medium">
                <PlusCircle className="w-4 h-4" />
                Make Prediction
              </button>
            </div>
          </DashboardCard>

          {/* Recent Activity */}
          <DashboardCard
            title="Recent Activity"
            description="Your latest transactions and updates"
            icon={<Activity className="w-5 h-5" />}
            iconBg="from-green-500 to-emerald-600"
          >
            <div className="flex flex-col items-center justify-center py-12">
              <div className="w-16 h-16 bg-gradient-to-br from-green-100 to-emerald-100 dark:from-green-900/30 dark:to-emerald-900/30 rounded-full flex items-center justify-center mb-4">
                <History className="w-8 h-8 text-green-600 dark:text-green-400" />
              </div>
              <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
                No Recent Activity
              </h3>
              <p className="text-slate-500 dark:text-slate-400 text-center mb-4">
                Your recent transactions will appear here
              </p>
              <button className="px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-lg transition-colors text-sm font-medium">
                View All Activity
              </button>
            </div>
          </DashboardCard>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
