import React from "react";

import { MarketChoiceData } from "@/app/types";
import { formatAmount } from "@/app/utils/utils";
import { Lock, Users, Clock, TrendingUp } from "lucide-react";

interface MarketCardProps {
  name: string;
  image: string;
  options: MarketChoiceData[];
  totalRevenue: string;
  onClick?: () => void;
  [key: string]: unknown;
  isClosed: boolean;
  category?: string;
  trending?: boolean;
  participants?: number;
  timeLeft?: string;
}

const MarketCard: React.FC<MarketCardProps> = ({
  name = "Untitled Market",
  options = [],
  totalRevenue = "$0",
  onClick,
  isClosed = false,
  category = "General",
  trending = false,
  participants = 0,
  timeLeft = "",
  ...props
}) => {
  const totalStaked = options.reduce((sum, option) => {
    return sum + BigInt(option.staked_amount);
  }, BigInt(0));

  const optionsWithOdds = options.map((option) => {
    const stakedAmount = BigInt(option.staked_amount);
    const odds =
      totalStaked > 0 ? Number((stakedAmount * BigInt(100)) / totalStaked) : 0;
    return {
      ...option,
      odds,
      name: option.label.toString(),
      price:
        totalStaked > 0
          ? ((Number(stakedAmount) / Number(totalStaked)) * 100).toFixed(2)
          : "0.00",
    };
  });

  const sortedOptions = [...optionsWithOdds].sort((a, b) => b.odds - a.odds);

  const getCategoryIcon = (cat: string) => {
    switch (cat.toLowerCase()) {
      case "crypto":
        return "₿";
      case "politics":
        return "🗳️";
      case "sports":
        return "⚽";
      default:
        return "📊";
    }
  };

  return (
    <div
      className="relative bg-white dark:bg-gray-950 rounded-xl overflow-hidden border border-gray-200/50 dark:border-gray-800/50 hover:border-gray-300 dark:hover:border-gray-700 transition-all duration-200 w-full h-full flex flex-col cursor-pointer group hover:shadow-sm"
      onClick={onClick}
      {...props}
    >
      {isClosed && (
        <div className="absolute inset-0 bg-white/80 dark:bg-gray-950/80 backdrop-blur-sm z-10 flex items-center justify-center rounded-xl">
          <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
            <Lock className="w-4 h-4" />
            <span className="font-medium text-sm">Market Closed</span>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="p-5 pb-3">
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-sm">
              {getCategoryIcon(category)}
            </div>
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              {category}
            </span>
          </div>
          {trending && (
            <div className="flex items-center gap-1 bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 px-2 py-1 rounded-md text-xs font-medium">
              <TrendingUp className="w-3 h-3" />
              Hot
            </div>
          )}
        </div>

        <h3 className="font-semibold text-gray-900 dark:text-white text-base leading-snug">
          {name}
        </h3>
      </div>

      {/* Options Grid */}
      <div className="px-5 pb-3 flex-1">
        <div className="grid grid-cols-2 gap-2">
          {sortedOptions.slice(0, 4).map((option, index) => {
            const isYes = /yes/i.test(option.name);
            const isNo = /no/i.test(option.name);

            const bgColor = isYes
              ? "bg-green-50 dark:bg-green-950"
              : isNo
              ? "bg-red-50 dark:bg-red-950"
              : "bg-gray-50 dark:bg-gray-900";

            const hoverColor = isYes
              ? "hover:bg-green-100 dark:hover:bg-green-900"
              : isNo
              ? "hover:bg-red-100 dark:hover:bg-red-900"
              : "hover:bg-gray-100 dark:hover:bg-gray-800";

            return (
              <div
                key={index}
                className={`p-3 rounded-lg ${bgColor} ${hoverColor} transition-colors duration-150`}
              >
                <div className="text-xs text-gray-600 dark:text-gray-400 mb-1 truncate">
                  {option.name}
                </div>
                <div className="text-sm font-semibold text-gray-900 dark:text-white">
                  {option.price}%
                </div>
              </div>
            );
          })}
        </div>

        {options.length > 4 && (
          <p className="text-xs text-gray-400 text-center mt-2">
            +{options.length - 4} more
          </p>
        )}
      </div>

      {/* Stats */}
      <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-800">
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1">
              <span className="font-medium text-gray-900 dark:text-white">
                {formatAmount(totalRevenue)}
              </span>
              <span className="text-gray-400">volume</span>
            </div>
            {participants > 0 && (
              <div className="flex items-center gap-1 text-gray-500 dark:text-gray-400">
                <Users className="w-3 h-3" />
                <span>{participants}</span>
              </div>
            )}
          </div>

          {timeLeft && (
            <div className="flex items-center gap-1 text-gray-400">
              <Clock className="w-3 h-3" />
              <span>{timeLeft}</span>
            </div>
          )}
        </div>
      </div>

      {/* Action Button */}
      <div className="p-5 pt-3">
        <button className="w-full bg-gradient-to-r from-green-300 to-green-500 dark:from-green-400 dark:to-green-500 text-white dark:text-gray-900 font-medium py-2.5 px-4 rounded-lg hover:opacity-90 transition-colors duration-150 text-sm">
          Trade
        </button>
      </div>
    </div>
  );
};

export default MarketCard;
