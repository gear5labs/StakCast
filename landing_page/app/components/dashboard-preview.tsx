"use client";

import { useRef, useEffect } from "react";
import { Button } from "./ui/button";
import SEO from "../../../shared/components/Seo"
import seoData from "../../../shared/components/seoData.json"; 

export function DashboardPreview() {
  const previewRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!previewRef.current) return;

      const { clientX, clientY } = e;
      const { left, top, width, height } = previewRef.current.getBoundingClientRect();

      const x = (clientX - left) / width;
      const y = (clientY - top) / height;

      const rotateY = 5 * (x - 0.5);
      const rotateX = -5 * (y - 0.5);

      previewRef.current.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    };

    const handleMouseLeave = () => {
      if (!previewRef.current) return;
      previewRef.current.style.transform = "perspective(1000px) rotateX(0deg) rotateY(0deg)";
    };

    const element = previewRef.current;
    if (element) {
      element.addEventListener("mousemove", handleMouseMove);
      element.addEventListener("mouseleave", handleMouseLeave);
    }

    return () => {
      if (element) {
        element.removeEventListener("mousemove", handleMouseMove);
        element.removeEventListener("mouseleave", handleMouseLeave);
      }
    };
  }, []);

  return (
    <>
      {/* SEO Component: Set meta tags for the comment section */}
      <SEO
            title={seoData.ctaSection.title} 
            description={seoData.ctaSection.description} 
            keywords={seoData.ctaSection.keywords} 
          />
          
      <section className="container mx-auto px-4 py-16" role="region" aria-labelledby="dashboard-preview-title">
        <h2 id="dashboard-preview-title" className="sr-only">{seoData.dashboardPreview.title}</h2>
        <div className="relative mx-auto max-w-5xl animate-on-scroll">
          <div
            ref={previewRef}
            className="aspect-[16/9] overflow-hidden rounded-2xl border bg-white dark:bg-slate-900 shadow-2xl transition-all duration-300 ease-out"
          >
            {/* Dashboard Mockup */}
            <div className="p-6 h-full">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-2">
                  <div className="h-8 w-8 rounded-lg bg-gradient-to-r from-emerald-500 to-blue-500"></div>
                  <span className="font-semibold">StakCast Dashboard Preview</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-8 w-8 rounded-full bg-gray-100 dark:bg-slate-800"></div>
                  <div className="h-8 w-20 rounded-full bg-gray-100 dark:bg-slate-800"></div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                {/* Feature Cards */}
                {["Total Staked", "Prediction Markets", "Your Earnings"].map((title, index) => (
                  <div key={index} className="rounded-xl bg-gray-50 dark:bg-slate-800 p-4 transition-all duration-300 hover:shadow-md">
                    <div className="mb-2 text-sm text-slate-500 dark:text-slate-400">Future Feature</div>
                    <div className="text-2xl font-bold">{title}</div>
                    <div className="mt-2 flex items-center text-xs text-emerald-500 dark:text-emerald-400">Coming Soon</div>
                  </div>
                ))}
              </div>

              <div className="mb-6">
                <div className="mb-4 flex items-center justify-between">
                  <h3 className="font-semibold">Example Markets (Coming Soon)</h3>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                  >
                    Preview
                  </Button>
                </div>
                <div className="space-y-3">
                  {[
                    { name: "Bitcoin above $75K by June", probability: "Example", volume: "Preview" },
                    { name: "ETH 2.0 launch in Q3", probability: "Example", volume: "Preview" },
                    { name: "US Election outcome", probability: "Example", volume: "Preview" },
                  ].map((market, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between rounded-lg bg-gray-50 dark:bg-slate-800 p-4 hover:bg-gray-100 dark:hover:bg-slate-700 transition-all duration-300 hover:shadow-md"
                    >
                      <div>
                        <div className="font-medium">{market.name}</div>
                        <div className="text-sm text-slate-500 dark:text-slate-400">Vol: {market.volume}</div>
                      </div>
                      <div className="text-right">
                        <div className="font-medium">{market.probability}</div>
                        <div className="text-sm text-emerald-500 dark:text-emerald-400">Coming Soon</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex justify-center">
                <div className="h-1.5 w-20 rounded-full bg-gray-200 dark:bg-slate-700"></div>
              </div>
            </div>
          </div>

          {/* Decorative elements - visible only in dark mode */}
          <div className="absolute -bottom-6 -left-6 h-12 w-12 rounded-xl bg-emerald-500/30 blur-xl hidden dark:block animate-pulse-slow"></div>
          <div className="absolute -top-6 -right-6 h-12 w-12 rounded-xl bg-blue-500/30 blur-xl hidden dark:block animate-pulse-slower"></div>
          <div className="absolute -bottom-3 right-1/4 h-6 w-6 rounded-full bg-purple-500/30 blur-lg hidden dark:block animate-float"></div>
        </div>
      </section>
    </>
  );
}