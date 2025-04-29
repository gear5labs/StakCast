import Link from "next/link";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { ExternalLink } from "lucide-react";
import SEO from "../../../shared/components/Seo"
import seoData from "../../../shared/components/seoData.json"; 
export function DevelopmentStatus() {
  const statuses = [
    {
      icon: (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-6 w-6"
        >
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
      ),
      title: "Beta Testing",
      description:
        "Our core platform is currently in beta testing. Visit our app to try it out!",
      action: (
        <Button
          variant="outline"
          size="sm"
          className="transition-all duration-300 hover:-translate-y-0.5 hover:shadow-sm"
        >
          <Link href="https://www.stakcast.com/">
            Visit App <ExternalLink className="ml-2 h-3 w-3" />
          </Link>
        </Button>
      ),
    },
    {
      icon: (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-6 w-6"
        >
          <circle cx="12" cy="12" r="10"></circle>
          <polyline points="12 6 12 12 16 14"></polyline>
        </svg>
      ),
      title: "Coming Soon",
      description:
        "Trading volume tracking and analytics will be available in our next release.",
      action: (
        <Badge className="bg-gray-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
          In Development
        </Badge>
      ),
    },
    {
      icon: (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-6 w-6"
        >
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
          <circle cx="9" cy="7" r="4"></circle>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
        </svg>
      ),
      title: "Join Now",
      description:
        "Our community is growing! Join our Discord to connect with other predictors.",
      action: (
        <Button
          variant="outline"
          size="sm"
          className="transition-all duration-300 hover:-translate-y-0.5 hover:shadow-sm"
        >
          Join Community
        </Button>
      ),
    },
    {
      icon: (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-6 w-6"
        >
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
        </svg>
      ),
      title: "Security Audit",
      description:
        "Our smart contracts are currently undergoing a comprehensive security audit.",
      action: (
        <Badge className="bg-gray-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">
          In Progress
        </Badge>
      ),
    },
  ];

  return (
    <>
       {/* SEO Component: Set meta tags for the comment section */}
       <SEO
            title={seoData.developmentStatus.title} 
            description={seoData.developmentStatus.description} 
            keywords={seoData.developmentStatus.keywords} 
          />
      <section className="container mx-auto px-4 py-20" role="region" aria-labelledby="development-status-title">
        <h2 id="development-status-title" className="sr-only">{seoData.developmentStatus.title}</h2>
        <div className="mb-16 text-center animate-on-scroll">
          <h2 className="mb-4 text-3xl font-bold md:text-4xl">
            Development Status
          </h2>
          <p className="mx-auto max-w-2xl text-slate-600 dark:text-slate-300">
            We&apos;re working hard to bring StakCast to life. Here&apos;s our current progress.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4">
          {statuses.map((status, i) => (
            <div
              key={i}
              className="rounded-2xl border bg-white dark:bg-slate-900 p-6 transition-all duration-300 hover:shadow-lg hover:-translate-y-1 animate-on-scroll"
              style={{ animationDelay: `${i * 100}ms` }}
            >
              <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500/10 to-blue-500/10 dark:from-emerald-500/20 dark:to-blue-500/20 transition-transform duration-300 group-hover:scale-110">
                {status.icon}
              </div>
              <h3 className="mb-2 text-xl font-semibold">{status.title}</h3>
              <p className="mb-4 text-slate-600 dark:text-slate-300">
                {status.description}
              </p>
              <div className="mt-4">{status.action}</div>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}