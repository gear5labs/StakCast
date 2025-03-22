"use client";
import React, { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { MarketCard } from "./components/ui";
import { SearchX } from "lucide-react";
import { DummyMarketType } from "./types";
import axios from "axios";
import Spinner from "./components/ui/loading/Spinner";

export default function Home() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const [allMarkets, setAllMarkets] = useState<DummyMarketType[]>([]);
  const [isLoading, setIsLoading] = useState(true); // Local loading state

  useEffect(() => {
    const fetchMarkets = async () => {
      try {
        const res = await axios.get("/api/dummy_data/");
        setAllMarkets(res.data);
      } catch (error) {
        console.log(error);
      } finally {
        setIsLoading(false); // Hide spinner after fetching (whether successful or not)
      }
    };

    fetchMarkets();
  }, []);

  const markets: DummyMarketType[] = Array.isArray(allMarkets)
    ? allMarkets
    : [];

  const filteredMarkets =
    currentCategory === "All"
      ? markets
      : markets.filter((market) =>
          market?.categories?.includes(currentCategory)
        );

  return (
    <>
      {isLoading ? ( // Show spinner if loading
        <Spinner />
      ) : filteredMarkets.length > 0 ? (
        <div className="md:flex flex-wrap md:grid-cols-2 gap-3 p-4">
          {filteredMarkets.map((market, index) => (
            <MarketCard
              key={index}
              name={market?.name || "Untitled Market"}
              image={market?.image || "/default-image.jpg"}
              options={market?.options || []}
              totalRevenue={market?.totalRevenue || "$0"}
              onClick={() => router.push(`/market/${market?.id}`)}
            />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center min-h-[50vh] text-center">
          <SearchX className="w-16 h-16 text-gray-400 mb-4" />
          <h3 className="text-xl font-semibold text-gray-700 mb-2">
            No Markets Found
          </h3>
          <p className="text-gray-500 max-w-md">
            {currentCategory === "All"
              ? "There are currently no markets available."
              : `No markets found in the "${currentCategory}" category.`}
          </p>
        </div>
      )}
    </>
  );
}
