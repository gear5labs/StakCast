"use client";
import React, { useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { MarketCard } from "./components/ui";
import { SearchX, Search, X } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import Header from "./components/layout/Header";
import { Providers } from "./provider";
import { useMarketData } from "./hooks/useMarket";
import { Market } from "./types";

const Home = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const [searchQuery, setSearchQuery] = useState("");
  const [searchFocused, setSearchFocused] = useState(false);

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
          <div className="mb-12 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
            <div>
              <h1 className="text-3xl font-light text-gray-900 dark:text-white mb-2">
                Markets
                {currentCategory !== "All" && (
                  <span className="text-gray-500 dark:text-gray-400">
                    {" "}
                    / {currentCategory}
                  </span>
                )}
              </h1>
              <p className="text-gray-500 dark:text-gray-400">
                Explore and trade on prediction markets
              </p>
            </div>

            <div className="relative w-full md:w-64 lg:w-80">
              <div
                className={`flex items-center border ${
                  searchFocused
                    ? "border-blue-500 ring-2 ring-blue-200 dark:ring-blue-900"
                    : "border-gray-200 dark:border-gray-700"
                } rounded-lg bg-white dark:bg-gray-800 px-3 py-2 transition-all duration-200`}
              >
                <Search className="w-4 h-4 text-gray-400 dark:text-gray-500 mr-2" />
                <Input
                  type="text"
                  placeholder="Search markets..."
                  className="flex-1 bg-transparent focus:border-none focus:outline-none text-gray-700 dark:text-gray-200 text-sm"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onFocus={() => setSearchFocused(true)}
                  onBlur={() => setSearchFocused(false)}
                />
                {searchQuery && (
                  <Button
                    onClick={() => setSearchQuery("")}
                    className="text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
                  >
                    <X className="w-4 h-4" />
                  </Button>
                )}
              </div>
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
              {filteredMarkets.map((market, index) => (
                <div
                  key={market?.market_id || index}
                  className="h-full transition-all duration-300 hover:-translate-y-1"
                >
                  <div className="h-full shadow-md hover:shadow-xl rounded-xl transition-all duration-300">
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
                      onClick={() =>
                        router.push(`/market/${market?.market_id}`)
                      }
                    />
                  </div>
                </div>
              ))}
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
                {searchQuery && (
                  <Button
                    onClick={() => setSearchQuery("")}
                    className="mt-4 text-blue-500 hover:text-blue-600 text-sm font-medium"
                  >
                    Clear search
                  </Button>
                )}
              </div>
            </div>
          )}
        </div>
      </Providers>
    </main>
  );
};

export default Home;
