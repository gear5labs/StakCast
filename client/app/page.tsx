"use client";
import React from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { MarketCard } from "./components/ui";
import { SearchX } from "lucide-react";

import { Button } from "@/components/ui/button";
import Header from "./components/layout/Header";
import { Providers } from "./provider";
import { useMarketData } from "./hooks/useMarket";
import { Market } from "./types";
import { useAppContext } from "./context/appContext";

const Home = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const { searchQuery } = useAppContext();

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

  const filteredMarkets = markets.filter((market) => {
    const query = searchQuery.toLowerCase();
    if (!query) return true;

    const nameMatch = market?.title?.toLowerCase().includes(query);
    const optionsMatch = ["No", "Yes"].some((label) =>
      label.toLowerCase().includes(query)
    ); // Optional improvement

    return nameMatch || optionsMatch;
  });

  // Function to check if market is closed
  const isMarketClosed = (marketId: string | number) => {
    return marketId?.toString() === "2" || marketId?.toString() === "1";
  };


  const handleMarketClick = (market: Market) => {
    if (!isMarketClosed(market?.market_id as number)) {
      router.push(`/market/${market?.market_id}`);
    }
  };

  if (error) {
    return (
      <main className="bg-gradient-to-b from-gray-50 to-white dark:from-gray-950 dark:to-gray-900 min-h-screen">
        <Providers>
          <Header />
          <div className="max-w-6xl mx-auto px-6 py-24">
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <div className="bg-white dark:bg-gray-900 p-8 rounded-xl shadow-md mb-6">
                <SearchX className="w-12 h-12 text-red-300 dark:text-red-600 mx-auto mb-4" />
                <h3 className="text-xl font-light text-gray-700 dark:text-gray-200 mb-2">
                  Error Loading Markets
                </h3>
                <p className="text-gray-500 max-w-md mb-4">{error}</p>
                <Button
                  onClick={refetch}
                  className="mt-4 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded"
                >
                  Try Again
                </Button>
              </div>
            </div>
          </div>
        </Providers>
      </main>
    );
  }

  return (
    <main className="bg-gradient-to-b from-gray-50 to-white dark:from-gray-950 dark:to-gray-900 min-h-screen">
      <Providers>
        <Header />
        <div className="max-w-6xl mx-auto px-6 py-24">
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
                const isClosed = isMarketClosed(market?.market_id as number);
                const timestamp = market.end_time;
                const milliseconds = Number(timestamp) * 1000;
                const date = new Date(milliseconds);
                console.log(date);

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
                              market?.choices?.[0]?.staked_amount?.toString() ||
                              "0",
                          },
                          {
                            label: "Yes",
                            staked_amount:
                              market?.choices?.[1]?.staked_amount?.toString() ||
                              "0",
                          },
                        ]}
                        totalRevenue={market?.total_pool?.toString() || "$0"}
                        onClick={() => handleMarketClick(market)}
                        isClosed={isClosed}
                        timeLeft={formatted}
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
      </Providers>
    </main>
  );
};

export default Home;
