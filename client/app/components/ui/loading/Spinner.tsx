import React from "react";
import SEO from "../../../../../shared/components/Seo";
import seoData from "../../../../../shared/components/seoData.json"
const Spinner = () => {
  return (
    <div 
    
    className="fixed inset-0 flex items-center justify-center bg-white bg-opacity-80 z-[9999]" 
    role="alert" 
    aria-live="polite" 
  >
        {/* SEO Component: Set meta tags for the comment section */}
        <SEO
      title={seoData.commentSection.title} 
      description={seoData.commentSection.description} 
      keywords={seoData.commentSection.keywords} 
    />
    <div 
      className="border-t-4 border-blue-500 border-solid rounded-full w-10 h-10 animate-spin" 
      aria-label="Loading..." 
    ></div>
  </div>

  );
};

export default Spinner;