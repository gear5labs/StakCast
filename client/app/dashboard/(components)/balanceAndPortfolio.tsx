import React from "react";
import { PieChart, Wallet } from "lucide-react";
import { useAppContext } from "../../context/appContext";

const BalanceAndPortfolio = () => {
  const { skPrice, balanceInUSD: balance } = useAppContext();
  return (
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
              <span className="font-semibold text-green-600">$1,255.68</span>
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
  );
};

export default BalanceAndPortfolio;
