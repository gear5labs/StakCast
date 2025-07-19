"use client";

import React, { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Target, User, Link2, Trophy, Search, X } from "lucide-react";
import { useAppContext } from "@/app/context/appContext";
import { Button } from "@/components/ui/button";
import { useMarketData } from "@/app/hooks/useMarket";

const Categories = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const { searchQuery, setSearchQuery } = useAppContext();
  const [searchFocused, setSearchFocused] = useState(false);
  const { counts } = useMarketData();

  const categories = [
    {
      name: "All Markets",
      slug: "All",
      icon: <Target size={16} />,
      count: counts.all,
    },
    {
      name: "General",
      slug: "General",
      icon: <User size={16} />,
      count: counts.general,
    },
    {
      name: "Crypto",
      slug: "Crypto",
      icon: <Link2 size={16} />,
      count: counts.crypto,
    },
    {
      name: "Sports",
      slug: "Sports",
      icon: <Trophy size={16} />,
      count: counts.sports,
    },
  ];

  const handleCategoryClick = (slug: string) => {
    if (slug === "All") {
      router.push("/");
    } else {
      router.push(`/?category=${slug}`);
    }
  };

  return (
    <div className="mx-1 md:mx-[3rem] lg:mx-[4rem] xl:mx-[5.1rem] w-full px-4 py-4 space-y-4 lg:space-y-0 lg:flex lg:items-center lg:justify-between">
      {/* Search Bar */}
      <div className="w-full max-w-xs lg:mr-4">
        <div
          className={`flex items-center border ${
            searchFocused
              ? "border-blue-500 ring-2 ring-blue-200 dark:ring-blue-900"
              : "border-gray-400 dark:border-gray-600"
          } rounded-md bg-white dark:bg-gray-800 px-3 py-2 transition-all duration-200`}
        >
          <Search className="w-4 h-4 text-gray-400 dark:text-gray-500 mr-2" />
          <input
            type="text"
            placeholder="Search markets..."
            className="flex-1 bg-transparent focus:outline-none text-sm text-gray-700 dark:text-gray-200"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onFocus={() => setSearchFocused(true)}
            onBlur={() => setSearchFocused(false)}
          />
          {searchQuery && (
            <Button
              onClick={() => setSearchQuery("")}
              className="text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300 p-0 h-auto"
            >
              <X className="w-4 h-4" />
            </Button>
          )}
        </div>
      </div>

      {/* Categories Scrollable Row */}
      <div className="flex gap-2 overflow-x-auto no-scrollbar lg:flex-1">
        {categories.map((cat) => {
          const isActive = currentCategory === cat.slug;

          return (
            <button
              key={cat.slug}
              onClick={() => handleCategoryClick(cat.slug)}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition whitespace-nowrap min-w-max ${
                isActive
                  ? "bg-gradient-to-r from-green-500 to-green-500 text-white"
                  : "bg-white text-black border border-gray-200 hover:bg-gray-100 dark:bg-gray-900 dark:border-gray-700 dark:text-white"
              }`}
            >
              {cat.icon}
              {cat.name}
              <span
                className={`ml-1 px-2 py-0.5 rounded-full text-xs font-semibold ${
                  isActive
                    ? "bg-white text-black"
                    : "bg-gray-100 dark:bg-gray-800"
                }`}
              >
                {cat.count}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default Categories;
