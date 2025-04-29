import Link from "next/link";
import { Button } from "./ui/button";
import { ChevronRight } from "lucide-react";
import SEO from "../../../shared/components/Seo"
import seoData from "../../../shared/components/seoData.json"; 
import { ObfuscatedSymbol } from "../../../shared/components/ObfuscatedSymbol";

export function CtaSection() {
  return (
    <>
       {/* SEO Component: Set meta tags for the comment section */}
          <SEO
            title={seoData.dashboardPreview.title} 
            description={seoData.dashboardPreview.description} 
            keywords={seoData.dashboardPreview.keywords} 
          />
          
      <section className="container mx-auto px-4 py-20">
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-emerald-600 to-blue-600 dark:from-emerald-900 dark:to-blue-900 p-8 md:p-12 animate-on-scroll">
          <div className="absolute -top-24 -right-24 h-64 w-64 rounded-full bg-emerald-500/20 blur-3xl animate-pulse-slow"></div>
          <div className="absolute -bottom-24 -left-24 h-64 w-64 rounded-full bg-blue-500/20 blur-3xl animate-pulse-slower"></div>

          <div className="relative z-10 flex flex-col items-center text-center md:flex-row md:text-left">
            <div className="md:w-2/3">
              <h2 className="mb-4 text-3xl font-bold md:text-4xl text-white">
                Ready to Start Predicting?
              </h2>
              <p className="mb-6 max-w-2xl text-white/80">
                Join our beta and be among the first to experience the future of
                prediction markets. Visit our app today and help shape the future
                of StakCast.
              </p>
              <div className="flex flex-col gap-4 sm:flex-row">
                <Button
                  size="lg"
                  className="bg-white text-slate-900 hover:bg-white/90 transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5"
                >
                  <Link href="https://www.stakcast.com/">
                    Visit App
                    <ChevronRight className="ml-2 h-4 w-4 animate-bounce-subtle" />
                  </Link>
                </Button>
                <Button
                  size="lg"
                  variant="outline"
                  className="border-white/20 text-white hover:bg-white/10 transition-all duration-300 hover:shadow-md hover:-translate-y-0.5"
                >
                  Join Community
                </Button>
              </div>
            </div>

            <div className="mt-8 md:mt-0 md:w-1/3">
              <div className="relative mx-auto h-40 w-40 md:h-48 md:w-48 animate-float-slow">
                <div className="absolute inset-0 rounded-full bg-gradient-to-r from-emerald-500/30 to-blue-500/30 blur-xl"></div>
                <div className="absolute inset-4 rounded-full bg-gradient-to-r from-emerald-500 to-blue-500"></div>
                <div className="absolute inset-8 flex items-center justify-center rounded-full bg-white text-4xl font-bold text-slate-900">
                <ObfuscatedSymbol symbol="STK" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}