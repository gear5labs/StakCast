"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";

// import { Button } from "./ui/button";
import { ExternalLink, Menu, X } from "lucide-react";
import Image from "next/image";
import ThemeToggle from "./theme-toggle";

export function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 w-full transition-all duration-300 ${
        isScrolled
          ? "bg-white/90 dark:bg-slate-950/90 backdrop-blur-md shadow-sm"
          : "bg-transparent"
      }`}
    >
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Image
              src="/stakcast-logo-2.png"
              alt="stakcast logo"
              height={150}
              width={150}
            />
          </div>

          <nav className="hidden md:flex items-center space-x-8">
            <Link
              href="#"
              className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white"
            >
              Home
            </Link>
            <Link
              href="#features"
              className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white"
            >
              Features
            </Link>
            <Link
              href="https://www.stakcast.com/howitworks"
              className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white"
            >
              How It Works
            </Link>
            <Link
              href="https://www.stakcast.com/"
              className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white flex items-center gap-1"
            >
              App <ExternalLink className="h-3 w-3" />
            </Link>
          </nav>

          <div className="hidden md:flex items-center gap-4">
            <ThemeToggle />
            <Button
              variant="ghost"
              className="transition-all duration-300 hover:-translate-y-0.5"
            >
              {/* <Link href="https://www.stakcast.com/">Visit App</Link> */}
            </Button>
            <Button className="bg-gradient-to-r from-emerald-500 to-blue-500 hover:from-emerald-600 hover:to-blue-600 text-white border-0 dark:text-white transition-all duration-300 hover:-translate-y-0.5 hover:shadow-md">
              <Link href="https://www.stakcast.com/">Get Started</Link>
            </Button>
          </div>

          <div className="flex items-center gap-2 md:hidden">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? (
                <X className="h-6 w-6" />
              ) : (
                <Menu className="h-6 w-6" />
              )}
            </Button>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden pt-4 pb-2 animate-fade-down">
            <nav className="flex flex-col space-y-4">
              <Link
                href="#"
                className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800"
                onClick={() => setMobileMenuOpen(false)}
              >
                Home
              </Link>
              <Link
                href="#features"
                className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800"
                onClick={() => setMobileMenuOpen(false)}
              >
                Features
              </Link>
              <Link
                href="https://www.stakcast.com/howitworks"
                className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800"
                onClick={() => setMobileMenuOpen(false)}
              >
                How It Works
              </Link>
              <Link
                href="https://www.stakcast.com/"
                className="text-sm font-medium text-slate-600 dark:text-slate-300 transition-colors duration-300 hover:text-slate-900 dark:hover:text-white p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center gap-1"
                onClick={() => setMobileMenuOpen(false)}
              >
                App <ExternalLink className="h-3 w-3" />
              </Link>
              <div className="pt-2 flex flex-col gap-2">
                <Button className="w-full bg-gradient-to-r from-emerald-500 to-blue-500 hover:from-emerald-600 hover:to-blue-600 text-white">
                  <Link href="https://www.stakcast.com/">Get Started</Link>
                </Button>
              </div>
              <ThemeToggle />
            </nav>
          </div>
        )}
      </div>
    </header>
  );
}
