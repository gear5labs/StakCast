"use client";
import React from "react";
import { useMarketContext } from "@/app/context/marketContext";
import { Market } from "@/app/types";

interface PurchaseSectionProps {
  market?: Market;
}

const PurchaseSection = ({ market }: PurchaseSectionProps) => {
  const { selectedOption, units, pricePerUnit, setUnits, handleOptionSelect } =
    useMarketContext();

  const handlePurchase = () => {
    if (!selectedOption || units <= 0) {
      console.log("Please select a choice and enter a valid number of units.");
      return;
    }

    const totalPrice = units * pricePerUnit;
    console.log(
      `Purchased ${units} units of "${selectedOption}" for $${totalPrice.toFixed(
        2
      )}`
    );
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
                    Staked: {String(choice.staked_amount)}
                  </span>
                </div>
              </button>
            );
          })}

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
            className="w-full px-3 py-2 border rounded-lg dark:bg-slate-900 dark:text-white"
          />
        </div>

        {/* Price Summary */}
        <p className="text-sm text-gray-600 dark:text-gray-300">
          Price per unit: ${pricePerUnit.toFixed(2)}
        </p>
        <p className="text-sm font-semibold text-gray-800 dark:text-white">
          Total: ${(units * pricePerUnit).toFixed(2)}
        </p>

        {/* Purchase Button */}
        <button
          onClick={handlePurchase}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-lg"
        >
          Purchase
        </button>
      </div>
    </div>
  );
};

export default PurchaseSection;
