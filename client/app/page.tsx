"use client";
import React from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { MarketCard } from "./components/ui";
import { SearchX } from "lucide-react";

import { Button } from "@/components/ui/button";
import Header from "./components/layout/Header";
import { useMarketData } from "./hooks/useMarket";
import { Market } from "./types";
import { useAppContext } from "./context/appContext";

import Modal from "./components/ui/Modal";
import PurchaseSection from "./components/sections/PurchaseSection";
// import { useState } from "react";
const Home = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const { searchQuery } = useAppContext();
// const [selectedOption, setSelectedOption] = useState<{
//   marketId: string;
//   option: string;
// } | null>(null);

  const getHookCategory = (urlCategory: string) => {
    switch (urlCategory.toLowerCase()) {
      case "crypto":
        return "crypto" as const;
      case "sports":
        return "sports" as const;
      default:
        return "all" as const;
    }
  };

  const {
    predictions: allMarkets,
    loading: isLoading,
    error,
    refetch,
  } = useMarketData({
    category: getHookCategory(currentCategory),
  });

  const markets: Market[] = Array.isArray(allMarkets) ? allMarkets : [];


  const [tab, setTab] = React.useState<"active" | "all">("active");
  const [modalOpen, setModalOpen] = React.useState(false);
  const [selectedMarket, setSelectedMarket] = React.useState<Market | null>(null);
  const [selectedOption, setSelectedOption] = React.useState<string | null>(null);


  const isMarketClosed = (market: Market) => {

    return !market.is_open || market.is_resolved;
  };


  const filteredMarkets = React.useMemo(() => {
    let filtered = markets.filter((market) => {
      const query = searchQuery.toLowerCase();
      if (!query) return true;
      const nameMatch = market?.title?.toLowerCase().includes(query);
      const optionsMatch = ["No", "Yes"].some((label) =>
        label.toLowerCase().includes(query)
      );
      return nameMatch || optionsMatch;
    });
    if (tab === "active") {
      filtered = filtered.filter((market) => !isMarketClosed(market));
    }
    return filtered;
  }, [markets, searchQuery, tab]);

  const handleMarketClick = (market: Market) => {
    if (!isMarketClosed(market)) {
      router.push(`/market/${market?.market_id}`);
    }
  };

  const handleOptionSelect = (market: Market, optionLabel: string) => {
    setSelectedMarket(market);
    setSelectedOption(optionLabel);
    setModalOpen(true);
  };

  if (error) {
    return (
      <main className=" dark:from-gray-950 dark:to-gray-900 min-h-screen">
        <Header />
        <div className="max-w-6xl mx-auto px-6 py-24">
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="bg-white dark:bg-gray-900 p-8 mb-6">
              <SearchX className="w-12 h-12 text-red-300 dark:text-red-600 mx-auto mb-4" />
              <h3 className="text-xl font-light text-gray-700 dark:text-gray-200 mb-2">
                Error Loading Markets
              </h3>
              <p className="text-gray-500 max-w-md mb-4">{error}</p>
              <Button
                onClick={refetch}
                className="mt-4 bg-green-600 hover:bg-blue-600 text-white px-4 py-2 rounded"
              >
                Try Again
              </Button>
            </div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="bg-gradient-to-b from-gray-50 to-white dark:from-gray-950 dark:to-gray-900 min-h-screen">
      <Header />
      {/* Tab Bar (not fixed) */}
      <div className="max-w-6xl mx-auto px-6 pt-24 flex justify-center">
        <div className="w-72 flex rounded-xl overflow-hidden shadow mb-6 border border-green-200 dark:border-green-800 bg-white dark:bg-gray-900">
          <div
            className={`flex-1 text-center py-2 cursor-pointer transition-all font-semibold text-base
                ${
                  tab === "active"
                    ? "bg-gradient-to-r from-green-400 to-green-600 text-white shadow-inner"
                    : "bg-white dark:bg-gray-900 text-green-700 dark:text-green-300 hover:bg-green-50 dark:hover:bg-green-950"
                }
              `}
            onClick={() => setTab("active")}
          >
            Active Markets
          </div>
          <div
            className={`flex-1 text-center py-2 cursor-pointer transition-all font-semibold text-base
                ${
                  tab === "all"
                    ? "bg-gradient-to-r from-green-400 to-green-600 text-white shadow-inner"
                    : "bg-white dark:bg-gray-900 text-green-700 dark:text-green-300 hover:bg-green-50 dark:hover:bg-green-950"
                }
              `}
            onClick={() => setTab("all")}
          >
            All Markets
          </div>
        </div>
      </div>
      <div className="max-w-6xl mx-auto px-6">
        <div className="mb-12">
          <div>
            {/* <h1 className="text-xl font-light text-gray-900 dark:text-white mb-2">
                Markets
                {currentCategory !== "All" && (
                  <span className="text-gray-500 dark:text-gray-400">
                    {" "}
                    / {currentCategory}
                  </span>
                )}
              </h1> */}
            {/* <p className="text-gray-500 dark:text-gray-400">
                Explore and trade on prediction markets
              </p> */}
          </div>
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 animate-pulse">
            {[...Array(6)].map((_, index) => (
              <div
                key={index}
                className="bg-white dark:bg-gray-900 rounded-xl h-72 w-full shadow-lg"
              ></div>
            ))}
          </div>
        ) : filteredMarkets.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {filteredMarkets.map((market, index) => {
              const isClosed = isMarketClosed(market);
              const timestamp = market.end_time;
              const milliseconds = Number(timestamp) * 1000;
              const date = new Date(milliseconds);

              const day = date.getUTCDate();
              const month = date.getUTCMonth() + 1;
              const year = date.getUTCFullYear() % 100;
              const formatted = `${day}/${month}/${year}`;

              return (
                <div
                  key={market?.market_id || index}
                  className={`h-full transition-all duration-300 ${
                    isClosed
                      ? "cursor-not-allowed"
                      : "hover:-translate-y-1 cursor-pointer"
                  }`}
                >
                  <div
                    className={`h-full shadow-md rounded-xl transition-all duration-300 ${
                      isClosed ? "opacity-75" : "hover:shadow-xl"
                    }`}
                  >
                    <MarketCard
                      name={market?.title || "Untitled Market"}
                      image={market?.image_url || "/default-image.jpg"}
                      options={[
                        {
                          label: "No",
                          staked_amount:
                            market?.total_shares_option_one.toString() || "0",
                        },
                        {
                          label: "Yes",
                          staked_amount:
                            market?.total_shares_option_two.toString() || "0",
                        },
                      ]}
                      totalRevenue={
                       market?.total_pool.toString()|| "$0"
                      }
                      onClick={() => handleMarketClick(market)}
                      isClosed={isClosed}
                      timeLeft={formatted}
                      onOptionSelect={(optionLabel) => handleOptionSelect(market, optionLabel)}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="bg-white dark:bg-gray-900 p-8 rounded-xl shadow-md mb-6">
              <SearchX className="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-4" />
              <h3 className="text-xl font-light text-gray-700 dark:text-gray-200 mb-2">
                {searchQuery ? "No Matching Markets" : "No Markets Found"}
              </h3>
              <p className="text-gray-500 max-w-md">
                {searchQuery
                  ? `No markets match your search for "${searchQuery}"`
                  : currentCategory === "All"
                  ? "There are currently no markets available."
                  : `No markets found in the "${currentCategory}" category.`}
              </p>
            </div>
          </div>
        )}
      </div>
      {/* Modal for PurchaseSection */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)}>
        {selectedMarket && (
          <PurchaseSection market={selectedMarket} preselectedOption={selectedOption} />
        )}
      </Modal>
    </main>
  );
};

export default Home;
