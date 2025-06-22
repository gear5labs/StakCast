import React from "react";
import Image from "next/image";

interface StakcastBannerProps {
  className?: string;
}

const StakcastBanner: React.FC<StakcastBannerProps> = ({ className = "" }) => {
  return (
    <div
      className={`relative h-72 w-full bg-gradient-to-br from-blue-600 via-purple-600 via-indigo-700 to-violet-800 rounded-3xl overflow-hidden shadow-2xl ${className}`}
    >
      {/* Animated Background Pattern */}
      <div className="absolute inset-0 bg-black/20">
        <div
          className="absolute inset-0 opacity-30 animate-pulse"
          style={{
            backgroundImage:
              "url(\"data:image/svg+xml,%3Csvg width='80' height='80' viewBox='0 0 80 80' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.08'%3E%3Ccircle cx='40' cy='40' r='2'/%3E%3Ccircle cx='20' cy='20' r='1.5'/%3E%3Ccircle cx='60' cy='20' r='1.5'/%3E%3Ccircle cx='20' cy='60' r='1.5'/%3E%3Ccircle cx='60' cy='60' r='1.5'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\")",
          }}
        ></div>
      </div>

      {/* Gradient Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/30 via-transparent to-transparent"></div>

      {/* Content Container */}
      <div className="relative z-1 h-full flex flex-col justify-between p-8">
        {/* Top Section - Logo and Starknet Badge */}
        <div className="flex items-start justify-between">
          <div className="flex items-center">
            <div className="relative w-20 h-20 mr-5 group">
              <div className="absolute inset-0 bg-white/20 rounded-2xl blur-sm group-hover:blur-none transition-all duration-300"></div>
              <div className="relative w-full h-full bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20 flex items-center justify-center">
                <Image
                  src="/stakcast-logo-1.png"
                  alt="Stakcast Logo"
                  width={56}
                  height={56}
                  className="object-contain"
                />
              </div>
            </div>
            <div className="text-white">
              <h2 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-white to-blue-100 bg-clip-text text-transparent">
                Stakcast
              </h2>
              <p className="text-blue-200 text-base font-medium">
                Prediction Markets
              </p>
            </div>
          </div>

          {/* Starknet Badge */}
          <div className="flex items-center bg-white/10 backdrop-blur-md rounded-full px-4 py-2 border border-white/20 hover:bg-white/20 transition-all duration-300">
            <div className="w-6 h-6 mr-2 relative">
              {/* Starknet Logo Placeholder - you can replace with actual Starknet logo */}
              <div className="w-full h-full bg-gradient-to-br from-orange-400 to-red-500 rounded-full flex items-center justify-center">
                <div className="w-3 h-3 bg-white rounded-sm transform rotate-45"></div>
              </div>
            </div>
            <span className="text-white text-sm font-semibold">
              Powered by Starknet
            </span>
          </div>
        </div>

        {/* Center Section - Main Tagline */}
        <div className="text-center flex-1 flex items-center justify-center">
          <div>
            <h1 className="text-5xl font-bold text-white mb-3 tracking-tight">
              Insight is{" "}
              <span className="bg-gradient-to-r from-yellow-300 via-yellow-200 to-orange-300 bg-clip-text text-transparent animate-pulse">
                Alpha
              </span>
            </h1>
            <p className="text-blue-100 text-xl font-light tracking-wide">
              Where predictions meet profits
            </p>
          </div>
        </div>

        {/* Bottom Section - Stats or Additional Info */}
        <div className="flex justify-center">
          <div className="flex space-x-8 text-center">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-2 border border-white/20">
              <div className="text-white font-bold text-lg">24/7</div>
              <div className="text-blue-200 text-xs">Active Markets</div>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-2 border border-white/20">
              <div className="text-white font-bold text-lg">∞</div>
              <div className="text-blue-200 text-xs">Possibilities</div>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl px-4 py-2 border border-white/20">
              <div className="text-white font-bold text-lg">L2</div>
              <div className="text-blue-200 text-xs">Scaling</div>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced Decorative Elements */}
      <div className="absolute top-8 right-8 w-32 h-32 bg-gradient-to-br from-yellow-300/20 to-orange-400/20 rounded-full blur-2xl animate-pulse"></div>
      <div className="absolute bottom-8 left-8 w-24 h-24 bg-gradient-to-tr from-blue-400/20 to-purple-400/20 rounded-full blur-xl animate-pulse delay-1000"></div>
      <div className="absolute top-1/2 left-1/4 w-16 h-16 bg-white/10 rounded-full blur-lg animate-bounce delay-500"></div>

      {/* Subtle Grid Lines */}
      <div className="absolute inset-0 opacity-10">
        <div
          className="absolute inset-0"
          style={{
            backgroundImage:
              "linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)",
            backgroundSize: "40px 40px",
          }}
        ></div>
      </div>

      {/* Floating Particles */}
      <div className="absolute top-1/4 right-1/3 w-2 h-2 bg-yellow-300/60 rounded-full animate-ping"></div>
      <div className="absolute bottom-1/3 right-1/4 w-1.5 h-1.5 bg-blue-300/60 rounded-full animate-ping delay-700"></div>
      <div className="absolute top-1/3 left-1/3 w-1 h-1 bg-purple-300/60 rounded-full animate-ping delay-1000"></div>
    </div>
  );
};

export default StakcastBanner;
