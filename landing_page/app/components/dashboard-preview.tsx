"use client";

import { useRef, useEffect } from "react";
import { Button } from "./ui/button";
import { useMarkets, useWallet } from "../hooks/useContract";

export function DashboardPreview() {
  const previewRef = useRef<HTMLDivElement>(null);
  const { markets, tvl, totalMarkets, loading, error } = useMarkets();
  const { isConnected, address, connecting, connectWallet, disconnectWallet } = useWallet();

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!previewRef.current) return;

      const { clientX, clientY } = e;
      const { left, top, width, height } =
        previewRef.current.getBoundingClientRect();

      const x = (clientX - left) / width;
      const y = (clientY - top) / height;

      const rotateY = 5 * (x - 0.5);
      const rotateX = -5 * (y - 0.5);

      previewRef.current.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    };

    const handleMouseLeave = () => {
      if (!previewRef.current) return;
      previewRef.current.style.transform =
        "perspective(1000px) rotateX(0deg) rotateY(0deg)";
    };

    const element = previewRef.current;
    if (element) {
      element.addEventListener("mousemove", handleMouseMove);
      element.addEventListener("mouseleave", handleMouseLeave);
    }

    return () => {
      if (element) {
        element.removeEventListener("mousemove", handleMouseMove);
        element.removeEventListener("mouseleave", handleMouseLeave);
      }
    };
  }, []);

  const formatTvl = (value: string) => {
    const num = parseFloat(value);
    if (num >= 1000000) {
      return `$${(num / 1000000).toFixed(1)}M`;
    } else if (num >= 1000) {
      return `$${(num / 1000).toFixed(1)}K`;
    }
    return `$${num.toFixed(2)}`;
  };

  const formatPoolValue = (value: string) => {
    const num = Number(value) / 1e18;
    if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}K STRK`;
    }
    return `${num.toFixed(2)} STRK`;
  };

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <section className="container mx-auto px-4 py-16">
      <div className="relative mx-auto max-w-5xl animate-on-scroll">
        <div
          ref={previewRef}
          className="aspect-[16/9] overflow-hidden rounded-2xl border bg-white dark:bg-slate-900 shadow-2xl transition-all duration-300 ease-out"
        >
          <div className="p-6 h-full">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-2">
                <div className="h-8 w-8 rounded-lg bg-gradient-to-r from-emerald-500 to-blue-500"></div>
                <span className="font-semibold text-slate-900 dark:text-white">
                  StakCast Dashboard
                </span>
              </div>
              <div className="flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-gray-100 dark:bg-slate-800"></div>
                <div className="h-8 w-20 rounded-full bg-gray-100 dark:bg-slate-800"></div>
              </div>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <div className="rounded-xl bg-gray-50 dark:bg-slate-800 p-4 transition-all duration-300 hover:shadow-md">
                <div className="mb-2 text-sm text-slate-500 dark:text-slate-400">
                  Total Value Locked
                </div>
                <div className="text-2xl font-bold text-slate-900 dark:text-white">
                  {loading ? (
                    <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded animate-pulse"></div>
                  ) : (
                    formatTvl(tvl)
                  )}
                </div>
                <div className="mt-2 flex items-center text-xs text-emerald-500 dark:text-emerald-400">
                  {loading ? "Loading..." : error ? "Demo Data" : "Live Data"}
                </div>
              </div>
              
              <div className="rounded-xl bg-gray-50 dark:bg-slate-800 p-4 transition-all duration-300 hover:shadow-md">
                <div className="mb-2 text-sm text-slate-500 dark:text-slate-400">
                  Active Markets
                </div>
                <div className="text-2xl font-bold text-slate-900 dark:text-white">
                  {loading ? (
                    <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded animate-pulse"></div>
                  ) : (
                    totalMarkets
                  )}
                </div>
                <div className="mt-2 flex items-center text-xs text-emerald-500 dark:text-emerald-400">
                  {loading ? "Loading..." : error ? "Demo Markets" : "Live Markets"}
                </div>
              </div>
              
              <div className="rounded-xl bg-gray-50 dark:bg-slate-800 p-4 transition-all duration-300 hover:shadow-md">
                <div className="mb-2 text-sm text-slate-500 dark:text-slate-400">
                  Your Portfolio
                </div>
                <div className="text-2xl font-bold text-slate-900 dark:text-white">
                  {isConnected ? "$125.50" : "$0.00"}
                </div>
                <div className="mt-2 flex items-center text-xs">
                  {isConnected ? (
                    <div className="flex items-center gap-2">
                      <div className="text-emerald-500 dark:text-emerald-400">
                        {formatAddress(address!)}
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={disconnectWallet}
                        className="h-6 px-2 text-xs text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
                      >
                        Disconnect
                      </Button>
                    </div>
                  ) : (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={connectWallet}
                      disabled={connecting}
                      className="h-6 px-2 text-xs text-emerald-500 dark:text-emerald-400 hover:text-emerald-600 dark:hover:text-emerald-300"
                    >
                      {connecting ? "Connecting..." : "Connect Wallet"}
                    </Button>
                  )}
                </div>
              </div>
            </div>

            {/* Markets */}
            <div className="mb-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="font-semibold text-slate-900 dark:text-white">
                  {loading ? "Loading Markets..." : "Live Markets"}
                </h3>
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                >
                  View All
                </Button>
              </div>
              <div className="space-y-3">
                {loading ? (
                  // Loading skeleton
                  [...Array(3)].map((_, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between rounded-lg bg-gray-50 dark:bg-slate-800 p-4 animate-pulse"
                    >
                      <div className="flex-1">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-2"></div>
                        <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
                      </div>
                      <div className="text-right">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-16 mb-1"></div>
                        <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-12"></div>
                      </div>
                    </div>
                  ))
                ) : markets.length > 0 ? (
                  markets.map((market) => (
                    <div
                      key={market.market_id}
                      className="flex items-center justify-between rounded-lg bg-gray-50 dark:bg-slate-800 p-4 hover:bg-gray-100 dark:hover:bg-slate-700 transition-all duration-300 hover:shadow-md cursor-pointer"
                    >
                      <div className="flex-1">
                        <div className="font-medium text-slate-900 dark:text-white">
                          {market.title.length > 45 
                            ? `${market.title.substring(0, 45)}...` 
                            : market.title}
                        </div>
                        <div className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                          <span className="inline-block bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 px-2 py-0.5 rounded-full text-xs mr-2">
                            {market.category}
                          </span>
                          Pool: {formatPoolValue(market.total_pool)}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-medium text-slate-900 dark:text-white">
                          {market.is_open ? "Active" : "Closed"}
                        </div>
                        <div className="text-sm text-emerald-500 dark:text-emerald-400">
                          {isConnected ? "Click to Predict" : "Connect Wallet"}
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center text-slate-500 dark:text-slate-400 py-8">
                    {error || "No active markets found."}
                  </div>
                )}
              </div>
            </div>

            <div className="flex justify-center">
              <div className="h-1.5 w-20 rounded-full bg-gray-200 dark:bg-slate-700"></div>
            </div>
          </div>
        </div>

        {/* Decorative elements */}
        <div className="absolute -bottom-6 -left-6 h-12 w-12 rounded-xl bg-emerald-500/30 blur-xl hidden dark:block animate-pulse-slow"></div>
        <div className="absolute -top-6 -right-6 h-12 w-12 rounded-xl bg-blue-500/30 blur-xl hidden dark:block animate-pulse-slower"></div>
        <div className="absolute -bottom-3 right-1/4 h-6 w-6 rounded-full bg-purple-500/30 blur-lg hidden dark:block animate-float"></div>
      </div>
    </section>
  );
}
