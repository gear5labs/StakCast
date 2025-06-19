import React from "react";

const ChartSection = () => {
  return (
    <div className="mt-8 p-6 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700">
      <h2 className="text-2xl font-bold text-gray-800 dark:text-white mb-6 border-b pb-4 border-gray-200 dark:border-gray-700">
        Market Trends
      </h2>
      <div className="w-full h-80 flex items-center justify-center bg-gray-50 dark:bg-gray-900 border border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-gray-500 dark:text-gray-400 text-lg italic p-4">
        {/* This is your enhanced placeholder */}
        <p className="text-center">
          📊 Chart visualization will appear here soon.
          <br />
          Stay tuned for insights!
        </p>
      </div>
    </div>
  );
};

export default ChartSection;
