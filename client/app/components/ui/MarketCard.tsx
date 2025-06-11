import React from "react";

import { MarketChoiceData } from "@/app/types";
import { formatAmount } from "@/app/utils/utils";

interface MarketCardProps {
  name: string;
  image: string;
  options: MarketChoiceData[];
  totalRevenue: string;
  onClick?: () => void;
  [key: string]: unknown;
}

const MarketCard: React.FC<MarketCardProps> = ({
  name = "Untitled Market",
  // image = "/default-image.jpg",
  options = [],
  totalRevenue = "$0",
  onClick,
  ...props
}) => {
  
  const totalStaked = options.reduce((sum, option) => {
    return sum + BigInt(option.staked_amount);
  }, BigInt(0));

  const optionsWithOdds = options.map(option => {
    const stakedAmount = BigInt(option.staked_amount);
    const odds = totalStaked > 0 
      ? Number((stakedAmount * BigInt(100)) / totalStaked)
      : 0;
    return {
      ...option,
      odds,
      name: option.label.toString()
    };
  });

  const sortedOptions = [...optionsWithOdds].sort((a, b) => b.odds - a.odds);
  const topOption = sortedOptions.length > 0 ? sortedOptions[0] : null;

  return (
    <div
      className="bg-white dark:bg-gray-900 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 w-full h-full flex flex-col cursor-pointer"
      onClick={onClick}
      {...props}
    >
      <div className="p-5 border-b border-gray-100 dark:border-gray-800">
        <h3 className="font-medium text-gray-900 dark:text-white text-lg leading-tight">
          {name}
        </h3>
      </div>

      <div className="p-5 flex-1 flex flex-col">
      
        {topOption && (
          <div className="mb-4 bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {topOption.name}
              </span>
              <span className="text-lg font-bold text-blue-600 dark:text-blue-400">
                {topOption.odds}%
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className="bg-blue-500 h-2 rounded-full"
                style={{
                  width: `${topOption.odds}%`
                }}
              ></div>
            </div>
          </div>
        )}

        {/* Other Options */}
        <div className="space-y-3 mb-4">
          {options?.length > 1
            ? sortedOptions.slice(1, 4).map((option, index) => (
                <div key={index} className="flex items-center justify-between">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {option.name}
                  </span>
                  <span className="text-sm font-medium text-gray-800 dark:text-gray-200">
                    {option.odds}%
                  </span>
                </div>
              ))
            : options.length === 0 && (
                <p className="text-sm text-gray-400 italic">
                  No options available
                </p>
              )}

          {options.length > 4 && (
            <p className="text-xs text-gray-400 text-right mt-1">
              +{options.length - 4} more
            </p>
          )}
        </div>
      </div>

      <div className="bg-gray-50 dark:bg-gray-800 p-4 flex justify-between items-center">
        <div>
          <p className="text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wider font-medium">
            Volume
          </p>
          <p className="text-sm font-medium text-gray-900 dark:text-white">
            {formatAmount(totalRevenue)}
          </p>
        </div>
        <div className="flex items-center space-x-1">
          <div className="h-2 w-2 rounded-full bg-green-500"></div>
          <span className="text-xs text-gray-500 dark:text-gray-400">Live</span>
        </div>
      </div>
    </div>
  );
};

export default MarketCard;
