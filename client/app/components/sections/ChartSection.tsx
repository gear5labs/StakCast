import React from 'react'
import SEO from "../layout/Seo"
import seoData from "../layout/seoData.json"
const ChartSection = () => {
  return (
<div className="mt-8">
      {/* SEO Component: Set meta tags for the chart section */}
      <SEO
        title={seoData.chartSection.title} 
        description={seoData.chartSection.description} 
        keywords={seoData.chartSection.keywords} 
      />
      
      <h2 className="text-xl font-semibold">Market Trends</h2>
      <div className="w-full h-64 bg-gray-100 dark:bg-slate-800 mt-4 rounded-lg shadow-inner">
        <p className="text-center text-gray-500 dark:text-white mt-28">Chart goes here</p>
      </div>
    </div>
  );
}

export default ChartSection