"use client";
import React, { useState } from "react";
import {
  Wallet,
  TrendingUp,
  PlusCircle,
  History,
  HelpCircle,
} from "lucide-react";
import { DummyMarketType } from "../types";
import { useAccount, useBalance } from "@starknet-react/core";
import Header from "../components/layout/Header";
import SEO from "../../../shared/components/Seo"; 
import seoData from "../../../shared/components/seoData.json"; 

const DashboardPage = () => {
  const { address, isConnected } = useAccount();
  const { data, isFetching } = useBalance({
    token: "0x04718f5a0Fc34cC1AF16A1cdee98fFB20C31f5cD61D6Ab07201858f4287c938D",
    address: address as "0x",
  });

  const balance = isFetching
    ? "loading..."
    : data?.formatted
      ? `${parseFloat(data.formatted).toFixed(2)} ${data.symbol}`
      : "";

  const [_markets, setMarkets] = useState<DummyMarketType[]>([]);
  const [newMarket, setNewMarket] = useState<Omit<DummyMarketType, "id">>({
    name: "",
    image: "",
    totalRevenue: "",
    categories: [],
    status: "inactive",
    startTime: 0,
    endTime: 0,
    createdBy: address || "",
    options: [],
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setNewMarket((prev) => ({ ...prev, [name]: value }));
  };

  const handleAddMarket = (e: React.FormEvent) => {
    e.preventDefault();
    setMarkets((prev) => [...prev, { ...newMarket, id: prev.length + 1 }]);
    setNewMarket({
      name: "",
      image: "",
      totalRevenue: "",
      categories: [],
      status: "inactive",
      startTime: 0,
      endTime: 0,
      createdBy: address || "",
      options: [],
    });
  };

  if (!isConnected) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-950">
        <Header />
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Connect Wallet to View Dashboard
          </h1>
          <p className="text-gray-600 dark:text-white">
            Please connect your wallet to access your dashboard.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* SEO Component: Set meta tags for the dashboard */}
      <SEO
        title={seoData.dashboard.title}
        description={seoData.dashboard.description}
        keywords={seoData.dashboard.keywords}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header Section */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">
            Welcome back, {address?.slice(0, 6)}...{address?.slice(-4)}
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatsCard
            title="Total Balance"
            value={balance || "0.00 ETH"}
            icon={<Wallet className="w-6 h-6" />}
            trend="+0.00%"
          />
          <StatsCard
            title="Active Positions"
            value="0"
            icon={<TrendingUp className="w-6 h-6" />}
            trend="0 markets"
          />
          <StatsCard
            title="Created Markets"
            value="0"
            icon={<PlusCircle className="w-6 h-6" />}
            trend="0 active"
          />
        </div>

        {/* Add Market Form */}
        <DashboardCard title="Create New Market">
          <form onSubmit={handleAddMarket} className="p-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Market Name
              </label>
              <input
                type="text"
                name="name"
                value={newMarket.name}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Image URL
              </label>
              <input
                type="text"
                name="image"
                value={newMarket.image}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>
            <button
              type="submit"
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
            >
              Create Market
            </button>
          </form>
        </DashboardCard>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-6">
            {/* Active Positions */}
            <DashboardCard title="Active Positions">
              <div className="p-6 text-center text-gray-500">
                <History className="w-12 h-12 mx-auto mb-4" />
                <p>No active positions yet</p>
              </div>
            </DashboardCard>

            {/* Created Markets */}
            <DashboardCard title="Your Created Markets">
              <div className="p-6 text-center text-gray-500">
                <PlusCircle className="w-12 h-12 mx-auto mb-4" />
                <p>You haven't created any markets yet</p>
              </div>
            </DashboardCard>
          </div>

          {/* Right Column */}
          <div className="space-y-6">
            {/* Quick Actions */}
            <DashboardCard title="Quick Actions">
              <div className="p-4 space-y-2">
                <QuickActionButton
                  label="Create New Market"
                  icon={<PlusCircle className="w-5 h-5" />}
                  onClick={() => {
                    /* Add navigation logic */
                  }}
                />
                <QuickActionButton
                  label="View Tutorial"
                  icon={<HelpCircle className="w-5 h-5" />}
                  onClick={() => {
                    /* Add navigation logic */
                  }}
                />
              </div>
            </DashboardCard>

            <DashboardCard title="Recent Activity">
              <div className="p-6 text-center text-gray-500">
                <History className="w-12 h-12 mx-auto mb-4" />
                <p>No recent activity</p>
              </div>
            </DashboardCard>
          </div>
        </div>
      </div>
    </div>
  );
};

const StatsCard = ({
  title,
  value,
  icon,
  trend,
}: {
  title: string;
  value: string;
  icon: React.ReactNode;
  trend: string;
}) => (
  <div className="bg-white rounded-2xl shadow-sm p-6">
    <div className="flex items-center justify-between mb-4">
      <h3 className="text-gray-500 text-sm">{title}</h3>
      <div className="text-blue-500">{icon}</div>
    </div>
    <div className="flex items-end justify-between">
      <div>
        <p className="text-2xl font-bold text-gray-900">{value}</p>
        <p className="text-sm text-gray-500">{trend}</p>
      </div>
    </div>
  </div>
);

const DashboardCard = ({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) => (
  <div className="bg-white rounded-2xl shadow-sm">
    <div className="px-6 py-4 border-b border-gray-100">
      <h3 className="font-semibold text-gray-900">{title}</h3>
    </div>
    {children}
  </div>
);

const QuickActionButton = ({
  label,
  icon,
  onClick,
}: {
  label: string;
  icon: React.ReactNode;
  onClick: () => void;
}) => (
  <button
    onClick={onClick}
    className="w-full flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-50 transition-colors"
  >
    <div className="text-blue-500">{icon}</div>
    <span className="text-gray-700">{label}</span>
  </button>
);

export default DashboardPage;