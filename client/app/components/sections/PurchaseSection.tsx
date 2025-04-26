import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useMarketContext } from "../../context/marketContext";
import { DummyMarketType } from "@/app/types";
import SEO from "../layout/Seo"; 
import seoData from "../layout/seoData.json"; 

const PurchaseSection = () => {
  const params = useParams();
  const { 
    markets,
    selectedOption, 
    units, 
    pricePerUnit, 
    setUnits, 
    handleOptionSelect 
  } = useMarketContext();
  
  const [market, setMarket] = useState<DummyMarketType | undefined>(undefined);
  
  useEffect(() => {
    const fetchedMarket = markets.find(
      (market) => market.id === Number(params.id)
    );
    setMarket(fetchedMarket as DummyMarketType);
  }, [params.id, markets]);

  const handlePurchase = () => {
    if (selectedOption && units > 0) {
      const totalPrice = units * pricePerUnit;
      console.log(
        `Purchased ${units} units of ${selectedOption} for $${totalPrice.toFixed(2)}`
      );
      // Add purchase logic here
    } else {
      console.log("Please select an option and enter a valid number of units.");
    }
  };

  return (
    <div className="mt-8">
      {/* SEO Component: Set meta tags for the purchase section */}
      <SEO
        title={seoData.purchaseSection.title} 
        description={seoData.purchaseSection.description} 
        keywords={seoData.purchaseSection.keywords} 
      />
      
      <h2 className="text-xl font-semibold">Make a Prediction</h2>
      <div className="flex flex-col space-y-4 mt-4">
        {market?.options.map((option, index) => (
          <button
            key={index}
            onClick={() => handleOptionSelect(option.name, option.odds as number)}
            className={`px-4 py-2 rounded-lg shadow-md ${
              selectedOption === option.name
                ? "bg-blue-700 text-white"
                : "bg-blue-600 text-white hover:bg-blue-700"
            }`}
          >
            {option.name}: {option.odds}%
          </button>
        ))}
      </div>

      {/* Units Input and Total Price */}
      {selectedOption && (
        <div className="mt-6 p-6 bg-white dark:bg-slate-950 rounded-lg shadow-lg max-w-lg mx-auto">
          <p className="text-xl font-semibold text-gray-800 dark:text-white">
            Selected Option:{" "}
            <span className="text-green-600">{selectedOption}</span>
          </p>
          <p className="mt-2 text-lg text-gray-600 dark:text-white">
            Price per unit:{" "}
            <span className="font-medium text-green-600">
              ${pricePerUnit.toFixed(2)}
            </span>
          </p>

          <div className="mt-4">
            <input
              type="number"
              value={units}
              onChange={(e) => setUnits(Number(e.target.value))}
              placeholder="Enter number of units"
              className="w-full px-4 py-3 text-lg border-2 border-gray-300 rounded-lg shadow-md focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500 transition duration-200 ease-in-out"
              aria-label="Number of units" // Accessibility: Label for screen readers
            />
          </div>

          <p className="mt-4 text-lg font-medium text-gray-800 dark:text-white">
            Total Price:{" "}
            <span className="text-green-600">
              ${units > 0 ? (units * pricePerUnit).toFixed(2) : "0.00"}
            </span>
          </p>

          <button
            onClick={handlePurchase}
            className="mt-6 w-full py-3 bg-green-600 text-white font-semibold rounded-lg shadow-md hover:bg-green-700 focus:outline-none focus:ring-4 focus:ring-green-500 transition duration-200 ease-in-out"
          >
            Purchase Units
          </button>
        </div>
      )}
    </div>
  );
};

export default PurchaseSection;