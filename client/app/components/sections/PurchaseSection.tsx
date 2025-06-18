"use client";
import React, { useState } from "react";
import { useMarketContext } from "@/app/context/marketContext";
import { Market } from "@/app/types";
import { useIsConnected } from "@/app/hooks/useIsConnected";
import WalletModal from "../ui/ConnectWalletModal";
import { formatAmount } from "@/app/utils/utils";
import { usePurchase } from "@/app/hooks/usePurchase";
import { useAppContext } from "@/app/context/appContext";
import {toast} from 'react-toastify'
interface PurchaseSectionProps {
  market?: Market;
}

export type Token = "STRK" | "SK";

const AVAILABLE_TOKENS: { value: Token; label: string; symbol: string }[] = [
  { value: "STRK", label: "Starknet Token", symbol: "STRK" },
  { value: "SK", label: "Stakcast Token", symbol: "SK" },
];

const PurchaseSection = ({ market }: PurchaseSectionProps) => {
  const { selectedOption, units, pricePerUnit, setUnits, handleOptionSelect } =
    useMarketContext();
  const connected = useIsConnected();
  const [showWalletModal, setShowWalletModal] = useState(false);
  const { selectedToken, setSelectedToken } = useAppContext();
  const { placeBet, loading } = usePurchase();
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
    console.log("category", market.category);

    console.log({
      market_id,
      choice_idx,
      amount,
      market_type,
    });
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

  return (
    <div>
      <h2 className="text-xl font-semibold mb-4 text-gray-800 dark:text-white">
        Make a Prediction
      </h2>

      <div className="space-y-4">
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
                className={`w-full px-4 py-2 rounded-lg border text-left ${
                  isActive
                    ? "bg-blue-100 border-blue-500 text-blue-700 dark:bg-blue-900 dark:text-white"
                    : "bg-gray-50 border-gray-300 hover:border-blue-400 dark:bg-slate-900 dark:text-white"
                }`}
              >
                <div className="flex justify-between">
                  <span className="font-medium">{label}</span>
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    Staked: {String(formatAmount(choice.staked_amount))}
                  </span>
                </div>
              </button>
            );
          })}

        {/* Token Selection Dropdown */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-white mb-1">
            Payment Token
          </label>
          <select
            value={selectedToken}
            onChange={(e) => setSelectedToken(e.target.value as Token)}
            className="w-full px-3 py-2 border rounded-lg dark:bg-slate-900 dark:text-white border-gray-300 dark:border-gray-600 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
          >
            {AVAILABLE_TOKENS.map((token) => (
              <option key={token.value} value={token.value}>
                {token.label} ({token.symbol})
              </option>
            ))}
          </select>
        </div>

        {/* Units Input */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-white mb-1">
            Units
          </label>
          <input
            type="number"
            value={units}
            onChange={(e) => setUnits(parseInt(e.target.value) || 0)}
            min={1}
            className="w-full px-3 py-2 border rounded-lg dark:bg-slate-900 dark:text-white border-gray-300 dark:border-gray-600 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <p className="text-sm text-gray-600 dark:text-gray-300">
          Price per unit: {pricePerUnit.toFixed(2)} {selectedToken}
        </p>
        <p className="text-sm font-semibold text-gray-800 dark:text-white">
          Total: {(units * pricePerUnit).toFixed(2)} {selectedToken}
        </p>

        <button
          onClick={handleClick}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={loading}
        >
          {loading
            ? "Processing..."
            : connected
            ? `Purchase with ${selectedToken}`
            : "Connect Wallet"}
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
