import React from "react";
import Header from "../components/layout/Header";
import { Wallet } from "lucide-react";

const Disconnected = () => {
  return (
    <div className="relative min-h-screen  dark:from-slate-950 dark:to-slate-900 flex flex-col">
      <Header />
      <div className="flex-grow flex items-center justify-center px-4">
        <div className="relative backdrop-blur-md bg-white/70 dark:bg-slate-900/50 border-slate-200 dark:border-slate-700  rounded-3xl p-10 max-w-lg w-full">
          <div className="flex flex-col items-center text-center space-y-6">
            <div className="w-20 h-20  flex items-center justify-center shadow-lg">
              <Wallet className="w-10 h-10 " />
            </div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-white">
              Connect Wallet
            </h1>
            <p className="text-slate-600 dark:text-slate-400 text-base">
              To continue to dashboard, please connect your wallet.
            </p>
         
          </div>
        </div>
      </div>
    </div>
  );
};

export default Disconnected;
