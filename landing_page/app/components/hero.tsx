"use client";

import { useEffect, useRef } from "react";
import Link from "next/link";
// import { Button } from "./ui/button";
import { Button } from "@/components/ui/button";
import { Badge } from "./ui/badge";
import { ArrowRight } from "lucide-react";

export function Hero() {
  const heroRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!heroRef.current) return;

      const { clientX, clientY } = e;
      const { left, top, width, height } =
        heroRef.current.getBoundingClientRect();

      const x = (clientX - left) / width;
      const y = (clientY - top) / height;

      const moveX = 20 * (x - 0.5);
      const moveY = 20 * (y - 0.5);

      const gradientElements =
        heroRef.current.querySelectorAll(".hero-gradient");
      gradientElements.forEach((el) => {
        (
          el as HTMLElement
        ).style.transform = `translate(${moveX}px, ${moveY}px)`;
      });
    };

    document.addEventListener("mousemove", handleMouseMove);
    return () => document.removeEventListener("mousemove", handleMouseMove);
  }, []);

  return (
    <section
      ref={heroRef}
      className="container mx-auto px-4 py-20 md:py-32 relative overflow-hidden"
    >
      {/* Decorative elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="hero-gradient absolute top-1/4 -right-20 h-64 w-64 rounded-full bg-blue-500/5 dark:bg-blue-500/10 blur-3xl transition-transform duration-300 ease-out"></div>
        <div className="hero-gradient absolute bottom-1/4 -left-20 h-64 w-64 rounded-full bg-emerald-500/5 dark:bg-emerald-500/10 blur-3xl transition-transform duration-300 ease-out"></div>
      </div>

      <div className="flex flex-col items-center text-center relative z-10 animate-fade-in">
        <Badge className="mb-4 bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 hover:bg-emerald-100 dark:hover:bg-emerald-900/40 transition-colors duration-300">
          Now on Testnet
        </Badge>
        <h1 className="mb-6 max-w-4xl text-4xl font-bold tracking-tight md:text-6xl lg:text-7xl">
          The Future of{" "}
          <span className="bg-gradient-to-r from-emerald-500 to-blue-500 bg-clip-text text-transparent dark:from-emerald-400 dark:to-blue-400 animate-gradient">
            Prediction Markets
          </span>
        </h1>
        <p className="mb-8 max-w-2xl text-lg text-slate-600 dark:text-slate-300 md:text-xl">
          Stake tokens, predict future events, and earn rewards in a
          decentralized marketplace. Join our community today.
        </p>
        <div className="flex flex-col gap-4 sm:flex-row">
          <Button
            size="lg"
            className="bg-gradient-to-r from-emerald-500 to-blue-500 hover:from-emerald-600 hover:to-blue-600 text-white border-0 dark:text-white transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5"
          >
            <Link href="https://www.stakcast.com/">
              Visit App
              <ArrowRight className="ml-2 h-4 w-4 animate-bounce-subtle" />
            </Link>
          </Button>
          <Link
            href="https://stakcast.com/howitworks"
            className="flex justify-center items-center text-center px-4 py-2 rounded border border-slate-300 dark:border-slate-700 transition-all duration-300 hover:shadow-md hover:-translate-y-0.5 hover:bg-slate-200 dark:hover:bg-slate-700 hover:text-black dark:hover:text-white"
          >
            Learn More
          </Link>
        </div>

        {/* Floating elements */}
        <div className="absolute top-1/4 right-10 h-16 w-16 rounded-full bg-gradient-to-r from-emerald-500/20 to-blue-500/20 hidden lg:block animate-float-slow"></div>
        <div className="absolute bottom-1/4 left-10 h-8 w-8 rounded-full bg-gradient-to-r from-blue-500/20 to-purple-500/20 hidden lg:block animate-float"></div>
      </div>
    </section>
  );
}
