"use client";
import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";

import { ArrowLeft, TrendingUp, MessageSquare } from "lucide-react";
// import { Activity } from "lucide-react";
import CommentSection from "@/app/components/sections/CommentSection";
import RecentActivity from "@/app/components/sections/RecentActivity";
import ChartSection from "@/app/components/sections/ChartSection";
import PurchaseSection from "@/app/components/sections/PurchaseSection";

import { Button } from "@/components/ui/button";
//import { useMarketContext } from "@/app/context/marketContext";
import { Market } from "@/app/types";
import { useMarketData } from "@/app/hooks/useMarket";
import Spinner from "@/app/components/ui/loading/Spinner";
import Image from "next/image";
// import StakcastBanner from "@/app/components/ui/banners/banner";

const Page = () => {
  const params = useParams();
  const router = useRouter();
  // const { units, pricePerUnit, selectedOption } = useMarketContext();
  const [activeTab, setActiveTab] = useState("chart");

  const { predictions: allMarkets, loading } = useMarketData();
  const [market, setMarket] = useState<Market | undefined>(undefined);

  useEffect(() => {
    if (!loading && Array.isArray(allMarkets)) {
      const fetchedMarket = allMarkets.find(
        (mkt) => String(mkt.market_id) === String(params.id)
      );
      setMarket(fetchedMarket);
    }
  }, [params.id, allMarkets, loading]);

  console.log(market);
  if (loading || !market) {
    return <Spinner />;
  }

  if (!market) {
    return (
      <div className="min-h-screen flex items-center justify-center text-gray-700 dark:text-white">
        Market not found.
      </div>
    );
  }

  const tabs = [
    { id: "chart", label: "Chart", icon: TrendingUp },
    // { id: "activity", label: "Activity", icon: Activity },
    { id: "comments", label: "Comments", icon: MessageSquare },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-950">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center space-x-4 mb-8">
          <Button
            onClick={() => router.push("/")}
            className="p-2 bg-inherit hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-600 dark:text-white" />
          </Button>

          <div className="flex items-center space-x-4">
            <Image
              src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcToDTzW1oRjiKNrGKqeI9Q7aMxTXVwbUcHa6Q&s"
              height={60}
              width={60}
              alt={market.title}
              className="rounded-lg object-cover"
            />

            <div>
              <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">
                {market.title}
              </h1>
              <p className="text-sm sm:text-base text-gray-600 dark:text-gray-300">
                {market.description}
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-6">
            {/* <div className="bg-white dark:bg-slate-950 rounded-2xl shadow-sm overflow-hidden">
              <StakcastBanner />
            </div> */}

            {/* Tabs Navigation */}
            <div className="bg-white dark:bg-slate-950 rounded-2xl shadow-sm p-4">
              <div className="flex space-x-4 border-b border-gray-200 dark:border-slate-700">
                {tabs.map((tab) => {
                  const isActive = activeTab === tab.id;
                  return (
                    <button
                      key={tab.id}
                      onClick={() => setActiveTab(tab.id)}
                      className={`flex items-center space-x-2 px-4 py-2 font-medium text-sm border-b-2 transition-all duration-200 ${
                        isActive
                          ? "border-blue-500 text-blue-600 dark:text-blue-400"
                          : "border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                      }`}
                    >
                      <tab.icon className="w-4 h-4" />
                      <span>{tab.label}</span>
                    </button>
                  );
                })}
              </div>

              {/* Tab Content */}
              <div className="mt-6">
                {activeTab === "chart" && <ChartSection />}
                {/* {activeTab === "activity" && <RecentActivity />} */}
                {activeTab === "comments" && <CommentSection />}
              </div>
              <RecentActivity />
            </div>
          </div>

          {/* Right Column */}
          <div className="lg:col-span-1">
            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm p-6 sticky top-8">
              <PurchaseSection market={market}  />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Page;
