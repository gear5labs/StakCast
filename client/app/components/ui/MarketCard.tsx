import React from "react";
import { MarketOption } from "@/app/types";
import seoData from "../../../../shared/components/seoData.json"; 
import { ObfuscatedSymbol } from "../../../../shared/components/ObfuscatedSymbol";
interface MarketCardProps {
  name: string;
  image: string;
  options: MarketOption[];
  totalRevenue: string;
  onClick?: () => void;
  [key: string]: unknown;
}

const MarketCard: React.FC<MarketCardProps> = ({
  name = "Untitled Market",
  options = [],
  totalRevenue = "$0",
  ...props
}) => {
  return (
    <div
      className="rounded-lg shadow-md hover:shadow-xl transition-shadow duration-200 border md:w-[30%] w-full mx-auto text-sm gap-3 mt-4"
      style={{ cursor: "pointer" }}
      role="article"
      aria-labelledby={`market-${name.replace(/\s+/g, '-')}`} 
      {...props}
    >
      <h3 id={`market-${name.replace(/\s+/g, '-')}`} className="sr-only">
        {name} - {totalRevenue} - {seoData.marketCard.description} 
      </h3>
      <div className="relative h-10 border border-gray-200 shadow-sm overflow-hidden rounded-t-lg m-auto">
        {/* Uncomment this when image is available */}
        {/* <Image
          src={image}
          alt={name}
          className="object-cover w-fit h-fit"
          height={100}
          width={100}
        /> */}
      </div>
      <div className="p-4 h-[14em] flex flex-col justify-between overflow-auto">
      <ObfuscatedSymbol symbol={name} />
        <p className="text-sm text-gray-600 dark:text-white mt-2">
          <span className="font-medium">Total Revenue:</span> {totalRevenue}
        </p>
        <div className="mt-2 space-y-2 overflow-auto text-sm">
          {options?.map((option, index) => (
            <div
              key={index}
              className="flex items-center justify-between bg-gray-100 dark:bg-gray-800 p-2 rounded-md"
            >
              <span className="text-sm font-medium text-gray-800 dark:text-white">
                {option.name}
              </span>
              <span className="text-sm font-bold text-blue-600">
                {option.odds}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default MarketCard;