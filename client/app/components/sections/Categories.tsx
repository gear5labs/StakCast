"use client";
import React from "react";
import SEO from "../../../../shared/components/Seo"; 
import seoData from "../../../../shared/components/seoData.json"; 
import { useRouter, useSearchParams } from "next/navigation";

const categories = [
  { name: "All", active: true },
  { name: "Crypto", active: false },
  { name: "Politics", active: false },
  { name: "Sports", active: false },
  { name: "Global Elections", active: false },
  { name: "Business", active: false },
];

const Categories = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get('category') || 'All';

  // Extract SEO data for categories
  const { title, description, keywords } = seoData.categories;

  const handleCategoryClick = (categoryName: string) => {
    if (categoryName === 'All') {
      router.push('/'); 
    } else {
      router.push(`/?category=${categoryName}`); 
    }
  };

  return (
    <div className="border-b">
      {/* SEO Component: Set meta tags for the categories section to improve discoverability */}
      <SEO
        title={title} 
        description={description} 
        keywords={keywords} 
      />
      <div className="flex space-x-4 p-4 overflow-x-auto whitespace-nowrap">
        {categories.map((category, index) => (
          <div
            key={index}
            onClick={() => handleCategoryClick(category.name)} 
            className={`cursor-pointer px-4 py-2 text-sm font-medium ${
              currentCategory === category.name
                ? "text-blue-500 border-b-2 border-blue-500" 
                : "text-gray-600 dark:text-white hover:text-black" 
            }`}
          >
            {category.name} 
          </div>
        ))}
      </div>
    </div>
  );
};

export default Categories;