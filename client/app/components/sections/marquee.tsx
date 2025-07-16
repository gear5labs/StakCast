import React from "react";

const MarqueeSection = () => {
  const messages = [
    "Stakcast: Insight is alpha",
    "Stakcast is now live on testnet",
    "Stakcast: Powered by starknet",
    "For partnerships and collaborations, reach contact@stakcast.com"
  ];



  const repeatedMessages = Array(8).fill(messages).flat();

  return (
    <div className="bg-gradient-to-r from-green-700 to-blue-700 dark:from-green-900 dark:to-blue-950 text-white py-2 overflow-hidden relative z-20 shadow-md">
      <div className="flex animate-marquee whitespace-nowrap">
        {repeatedMessages.map((message, index) => (
          <span
            key={index}
            className="inline-block px-8 text-sm font-semibold opacity-90 hover:opacity-100 transition-opacity"
          >
            {message}
          </span>
        ))}
      </div>

      <style jsx>{`
        @keyframes marquee {
          0% {
            transform: translateX(0%);
          }
          100% {
            transform: translateX(-100%);
          }
        }

        .animate-marquee {
          animation: marquee 40s linear infinite;
        }

        .animate-marquee:hover {
          animation-play-state: paused;
        }
      `}</style>
    </div>
  );
};

export default MarqueeSection;
