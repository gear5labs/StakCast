"use client";
import React, { useMemo, useState } from "react";
import { useMarketContext } from "@/app/context/marketContext";
import { Market } from "@/app/types";
import { useIsConnected } from "@/app/hooks/useIsConnected";
import WalletModal from "../ui/ConnectWalletModal";
import {  normalizeWEI } from "@/app/utils/utils";
import { usePurchase } from "@/app/hooks/usePurchase";
import { useAppContext } from "@/app/context/appContext";
import { toast } from "react-toastify";
import {
  ChevronDown,
  TrendingUp,
  TrendingDown,
  Wallet,
  CheckCircle,
  AlertTriangle,
} from "lucide-react";

interface PurchaseSectionProps {
  market?: Market;
}

export type Token = "STRK" | "SK";

// const AVAILABLE_TOKENS: {
//   value: Token;
//   label: string;
//   symbol: string;
//   logo: string;
//   color: string;
//   disabled?: boolean;
// }[] = [
//   {
//     value: "STRK",
//     label: "Starknet Token",
//     symbol: "STRK",
//     logo: "/logos/starknet-logo.svg",
//     color: "from-purple-500 to-blue-500",
//   },
//   {
//     value: "SK",
//     label: "Stakcast Token",
//     symbol: "SK",
//     logo: "/stakcast-logo-1.png",
//     color: "from-green-500 to-emerald-500",
//     disabled: true, 
//   },
// ];

const PurchaseSection = ({ market }: PurchaseSectionProps) => {
  const {
    selectedOption,
    handleOptionSelect,
    unitsToStake,
    setUnitsToStake,
  } = useMarketContext();
  const connected = useIsConnected();
  const [showWalletModal, setShowWalletModal] = useState(false);
//  const [showTokenDropdown, setShowTokenDropdown] = useState(false);
  const { selectedToken, setSelectedToken } = useAppContext();
  const { placeBet, loading } = usePurchase();
  React.useEffect(() => {
    setSelectedToken("STRK");
  }, [setSelectedToken]);

  // const selectedTokenData = AVAILABLE_TOKENS.find(
  //   (token) => token.value === selectedToken
  // );

  const handlePurchase = () => {
    console.log(selectedOption, unitsToStake, market);
    if (!selectedOption || +unitsToStake <= 0 || !market) {
      toast.error("Please select a choice and enter a valid number of units.");
      return;
    }
   
    if (unitsToStake < 1) {
      toast.error("Minimum stake required: 1 STRK");
      return;
    }

    const market_id: number = market.market_id as number;
    const choice_idx = selectedOption === "Yes" ? 1 : 0;

  
    const amount = unitsToStake;

    console.log(
      `Placing bet on "${selectedOption}" with market_id=${market_id}, choice_idx=${choice_idx}, amount=${amount}, token=${selectedToken}`
    );
    placeBet(market_id, choice_idx, amount * 10 ** 18);
  };

  const handleClick = () => {
    if (connected) {
      handlePurchase();
    } else {
      setShowWalletModal(true);
    }
  };

  // const handleTokenSelect = (token: Token) => {

  //   if (token === "STRK") {
  //     setSelectedToken(token);
  //   }
  //   setShowTokenDropdown(false);
  // };

  const inputValue = useMemo(() => {
    return unitsToStake.toString();
  }, [unitsToStake]);

  return (
    <div className="bg-white dark:bg-slate-800 rounded-2xl p-4 shadow-lg border border-gray-100 dark:border-slate-700 max-w-md mx-auto">
      <div className="flex items-center gap-2 mb-4">
        <div className="p-1.5 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg">
          <TrendingUp className="w-4 h-4 text-white" />
        </div>
        <h2 className="text-lg font-bold text-gray-900 dark:text-white">
          Make a Prediction
        </h2>
      </div>

      {/* Minimum Stake Warning */}
      <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
        <div className="flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 text-yellow-600 dark:text-yellow-400" />
          <span className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
            Minimum stake required: 1 STRK
          </span>
        </div>
      </div>

      <div className="space-y-4">
        {/* Prediction Options */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Choose Your Prediction
          </label>
          {market &&
            [0, 1].map((key) => {
              const label = key === 1 ? "Yes" : "No";
              const isActive = selectedOption === label;
              const odds = 1;

              const poolAmount =
                key === 1
                  ? market.total_shares_option_one
                  : market.total_shares_option_two;
              return (
                <button
                  key={key}
                  onClick={() =>
                    handleOptionSelect(label, odds, odds.toString())
                  }
                  className={`group w-full p-3 rounded-lg border-2 transition-all duration-200 ${
                    isActive
                      ? label === "Yes"
                        ? "bg-gradient-to-r from-green-50 to-emerald-50 border-green-300 dark:from-green-900/20 dark:to-emerald-900/20 dark:border-green-600"
                        : "bg-gradient-to-r from-red-50 to-pink-50 border-red-300 dark:from-red-900/20 dark:to-pink-900/20 dark:border-red-600"
                      : "bg-gray-50 border-gray-200 hover:border-gray-300 hover:shadow-md dark:bg-slate-700 dark:border-slate-600 dark:hover:border-slate-500"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div
                        className={`p-1.5 rounded-lg ${
                          label === "Yes"
                            ? "bg-green-100 dark:bg-green-900/50"
                            : "bg-red-100 dark:bg-red-900/50"
                        }`}
                      >
                        {label === "Yes" ? (
                          <TrendingUp
                            className={`w-3 h-3 ${
                              isActive
                                ? "text-green-600 dark:text-green-400"
                                : "text-green-500"
                            }`}
                          />
                        ) : (
                          <TrendingDown
                            className={`w-3 h-3 ${
                              isActive
                                ? "text-red-600 dark:text-red-400"
                                : "text-red-500"
                            }`}
                          />
                        )}
                      </div>
                      <div className="text-left">
                        <div
                          className={`font-bold text-base ${
                            isActive
                              ? label === "Yes"
                                ? "text-green-700 dark:text-green-300"
                                : "text-red-700 dark:text-red-300"
                              : "text-gray-700 dark:text-gray-300"
                          }`}
                        >
                          {label}
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">
                        Pool
                      </div>
                      <div className="font-semibold text-sm text-gray-700 dark:text-gray-300">
                        {String(normalizeWEI(poolAmount))+'%'}
                      </div>
                    </div>
                  </div>
                  {isActive && (
                    <div className="mt-1 flex justify-center">
                      <CheckCircle className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                    </div>
                  )}
                </button>
              );
            })}
        </div>

        {/* Token Selection - Disabled for now */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Payment Token
          </label>
          <div className="relative">
            <button
              disabled
              className="w-full p-3 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg opacity-50 cursor-not-allowed"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded-full bg-gradient-to-r from-purple-500 to-blue-500 flex items-center justify-center">
                    <span className="text-white font-bold text-xs">S</span>
                  </div>
                  <div className="text-left">
                    <div className="font-semibold text-sm text-gray-900 dark:text-white">
                      STRK
                    </div>
                  </div>
                </div>
                <ChevronDown className="w-4 h-4 text-gray-400" />
              </div>
            </button>
          </div>
        </div>

        {/* Number of Units */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Number Of Units (STRK)
          </label>
          <div className="relative">
            <input
              type="number"
              value={unitsToStake || 0}
              onChange={(e) => setUnitsToStake(parseInt(e.target.value) || 0)}
              min={30}
              placeholder="Enter amount (min 30)"
              className="w-full p-3 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 dark:text-white font-semibold"
            />
          </div>
        </div>

        {/* Amount Display */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Total Amount
          </label>
          <div className="relative">
            <input
              type="number"
              value={inputValue || 0}
              disabled
              min={30}
              placeholder="Total amount"
              className="w-full p-3 pr-12 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 dark:text-white font-semibold"
            />
            <div className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 dark:text-gray-400 text-sm font-medium">
              STRK
            </div>
          </div>
        </div>

        {/* Price Summary */}
        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-3 border border-blue-100 dark:border-blue-800">
          <div className="flex justify-between items-center mb-1">
            <span className="text-xs text-gray-600 dark:text-gray-400">
              Units to stake:
            </span>
            <span className="font-semibold text-sm text-gray-900 dark:text-white">
              {unitsToStake} STRK
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">
              Total:
            </span>
            <span className="text-lg font-bold text-blue-600 dark:text-blue-400">
              {`${inputValue} STRK`}
            </span>
          </div>
        </div>

        {/* Purchase Button */}
        <button
          onClick={handleClick}
          disabled={loading || unitsToStake < 1}
          className={`w-full py-3 px-4 rounded-lg font-bold transition-all duration-200 flex items-center justify-center gap-2 ${
            loading || unitsToStake < 1
              ? "bg-gray-400 cursor-not-allowed"
              : connected
              ? "bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
              : "bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
          }`}
        >
          {loading ? (
            <>
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              Processing...
            </>
          ) : connected ? (
            <>
              <TrendingUp className="w-4 h-4" />
              Place Prediction
            </>
          ) : (
            <>
              <Wallet className="w-4 h-4" />
              Connect Wallet
            </>
          )}
        </button>
      </div>

      {/* Wallet Modal */}
      {showWalletModal && (
        <WalletModal onClose={() => setShowWalletModal(false)} />
      )}
    </div>
  );
};

export default PurchaseSection;
