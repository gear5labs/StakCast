"use client";
import React, { useState } from "react";
import { useMarketContext } from "@/app/context/marketContext";
import { Market } from "@/app/types";
import { useIsConnected } from "@/app/hooks/useIsConnected";
import WalletModal from "../ui/ConnectWalletModal";
import { formatAmount } from "@/app/utils/utils";
import { usePurchase } from "@/app/hooks/usePurchase";
import { useAppContext } from "@/app/context/appContext";
import { toast } from "react-toastify";
import {
  ChevronDown,
  TrendingUp,
  TrendingDown,
  Wallet,
  CheckCircle,
} from "lucide-react";

interface PurchaseSectionProps {
  market?: Market;
}

export type Token = "STRK" | "SK";

const AVAILABLE_TOKENS: {
  value: Token;
  label: string;
  symbol: string;
  logo: string;
  color: string;
}[] = [
  {
    value: "STRK",
    label: "Starknet Token",
    symbol: "STRK",
    logo: "/logos/starknet-logo.svg", // Add your actual logo path
    color: "from-purple-500 to-blue-500",
  },
  {
    value: "SK",
    label: "Stakcast Token",
    symbol: "SK",
    logo: "/stakcast-logo-1.pnleg", // Add your actual logo path
    color: "from-green-500 to-emerald-500",
  },
];

const PurchaseSection = ({ market }: PurchaseSectionProps) => {
  const { selectedOption, units, pricePerUnit, setUnits, handleOptionSelect } =
    useMarketContext();
  const connected = useIsConnected();
  const [showWalletModal, setShowWalletModal] = useState(false);
  const [showTokenDropdown, setShowTokenDropdown] = useState(false);
  const { selectedToken, setSelectedToken } = useAppContext();
  const { placeBet, loading } = usePurchase();

  const selectedTokenData = AVAILABLE_TOKENS.find(
    (token) => token.value === selectedToken
  );

  const handlePurchase = () => {
    if (!selectedOption || units <= 0 || !market) {
      toast.error("Please select a choice and enter a valid number of units.");
      return;
    }

    const market_id = +market.market_id.toString(16);
    const choice_idx = selectedOption === "Yes" ? 0x1 : 0x0;
    const amount = (units * 10 ** 18) as number;
    const market_type = 0;

    console.log(
      `Placing bet on "${selectedOption}" with market_id=${market_id}, choice_idx=${choice_idx}, amount=${amount}, market_type=${market_type}, token=${selectedToken}`
    );

    placeBet(market_id, choice_idx, amount, market_type);
  };

  const handleClick = () => {
    if (connected) {
      handlePurchase();
    } else {
      setShowWalletModal(true);
    }
  };

  const handleTokenSelect = (token: Token) => {
    setSelectedToken(token);
    setShowTokenDropdown(false);
  };

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

      <div className="space-y-4">
        {/* Prediction Options */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Choose Your Prediction
          </label>
          {market?.choices &&
            [0, 1].map((key) => {
              const choice = market.choices[key as 0 | 1];
              const label = key === 1 ? "Yes" : "No";
              const isActive = selectedOption === label;
              const odds = 1;

              return (
                <button
                  key={key}
                  onClick={() => handleOptionSelect(label, odds)}
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
                        {String(formatAmount(choice.staked_amount))}
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

        {/* Token Selection */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Payment Token
          </label>
          <div className="relative">
            <button
              onClick={() => setShowTokenDropdown(!showTokenDropdown)}
              className="w-full p-3 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg hover:border-gray-300 dark:hover:border-slate-500 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div
                    className={`w-6 h-6 rounded-full bg-gradient-to-r ${selectedTokenData?.color} flex items-center justify-center`}
                  >
                    <span className="text-white font-bold text-xs">
                      {selectedTokenData?.symbol.charAt(0)}
                    </span>
                  </div>
                  <div className="text-left">
                    <div className="font-semibold text-sm text-gray-900 dark:text-white">
                      {selectedTokenData?.symbol}
                    </div>
                  </div>
                </div>
                <ChevronDown
                  className={`w-4 h-4 text-gray-400 transition-transform duration-200 ${
                    showTokenDropdown ? "rotate-180" : ""
                  }`}
                />
              </div>
            </button>

            {showTokenDropdown && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg shadow-lg z-10 overflow-hidden">
                {AVAILABLE_TOKENS.map((token) => (
                  <button
                    key={token.value}
                    onClick={() => handleTokenSelect(token.value)}
                    className="w-full p-3 hover:bg-gray-50 dark:hover:bg-slate-600 transition-colors duration-150 flex items-center gap-2"
                  >
                    <div
                      className={`w-6 h-6 rounded-full bg-gradient-to-r ${token.color} flex items-center justify-center`}
                    >
                      <span className="text-white font-bold text-xs">
                        {token.symbol.charAt(0)}
                      </span>
                    </div>
                    <div className="text-left">
                      <div className="font-semibold text-sm text-gray-900 dark:text-white">
                        {token.symbol}
                      </div>
                    </div>
                    {selectedToken === token.value && (
                      <CheckCircle className="w-4 h-4 text-blue-600 dark:text-blue-400 ml-auto" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Units Input */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
            Amount
          </label>
          <div className="relative">
            <input
              type="number"
              value={units}
              onChange={(e) => setUnits(parseInt(e.target.value) || 0)}
              min={1}
              placeholder="Enter amount"
              className="w-full p-3 pr-12 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 dark:text-white font-semibold"
            />
            <div className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 dark:text-gray-400 text-sm font-medium">
              {selectedToken}
            </div>
          </div>
        </div>

        {/* Price Summary */}
        <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-3 border border-blue-100 dark:border-blue-800">
          <div className="flex justify-between items-center mb-1">
            <span className="text-xs text-gray-600 dark:text-gray-400">
              Price per unit:
            </span>
            <span className="font-semibold text-sm text-gray-900 dark:text-white">
              {pricePerUnit.toFixed(2)} {selectedToken}
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">
              Total:
            </span>
            <span className="text-lg font-bold text-blue-600 dark:text-blue-400">
              {(units * pricePerUnit).toFixed(2)} {selectedToken}
            </span>
          </div>
        </div>

        {/* Purchase Button */}
        <button
          onClick={handleClick}
          disabled={loading}
          className={`w-full py-3 px-4 rounded-lg font-bold transition-all duration-200 flex items-center justify-center gap-2 ${
            loading
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
