
"use client"; 
import { useEffect, useRef } from "react";

export const ObfuscatedSymbol = ({ symbol }: { symbol: string }) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (ref.current) {
      const hidden = ref.current.getAttribute("data-symbol");
      ref.current.textContent = hidden;
    }
  }, []);

  return <div ref={ref} data-symbol={symbol} className="market-symbol" />;
};
