"use client";

import React from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Target, User, Link2, Trophy } from "lucide-react";

const categories = [
  { name: "All Markets", slug: "All", icon: <Target size={16} />, count: 10 },
  { name: "General", slug: "General", icon: <User size={16} />, count: 0 },
  { name: "Crypto", slug: "Crypto", icon: <Link2 size={16} />, count: 0 },
  { name: "Sports", slug: "Sports", icon: <Trophy size={16} />, count: 0 },
];

const Categories = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";

  const handleCategoryClick = (slug: string) => {
    if (slug === "All") {
      router.push("/");
    } else {
      router.push(`/?category=${slug}`);
    }
  };

  return (
    <div className="flex items-center gap-2 px-4 py-4 overflow-x-auto">
      <input
        placeholder="Search markets..."
        className="px-4 py-2 rounded-md border border-gray-400 text-sm text-gray-700 w-full max-w-xs focus:outline-none"
      />
      {categories.map((cat) => {
        const isActive = currentCategory === cat.slug;

        return (
          <button
            key={cat.slug}
            onClick={() => handleCategoryClick(cat.slug)}
            className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition ${
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
  );
};

export default Categories;
