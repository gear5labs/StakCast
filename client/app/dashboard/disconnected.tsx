import React, { useState } from "react";
import Header from "../components/layout/Header";
import { Button } from "@/components/ui/button";
import WalletModal from "../components/ui/ConnectWalletModal";

const Disconnected = () => {
  const [openModal, setOpenModal] = useState(false);

  return (
    <div className="relative min-h-screen bg-gradient-to-br from-white to-slate-100 dark:from-slate-950 dark:to-slate-900 flex flex-col">
      <Header />
      <div className="flex-grow flex items-center justify-center px-4 py-10">
        <div className="relative rounded-3xl bg-white/80 dark:bg-slate-800/60 backdrop-blur-xl border border-slate-200 dark:border-slate-700 shadow-2xl p-10 max-w-md w-full transition-all text-center">
          <div className="mb-6">
            <svg
              className="mx-auto w-32 h-32 mb-4"
              viewBox="0 0 200 200"
              xmlns="http://www.w3.org/2000/svg"
            >
              <circle cx="100" cy="100" r="100" fill="#c7d2fe" />
              <path
                d="M140 90H60c-5.523 0-10 4.477-10 10v30c0 5.523 4.477 10 10 10h80c5.523 0 10-4.477 10-10v-30c0-5.523-4.477-10-10-10zm-40 35a5 5 0 110-10 5 5 0 010 10z"
                fill="#4f46e5"
              />
              <path
                d="M60 80l6-20h68l6 20"
                fill="none"
                stroke="#6366f1"
                strokeWidth="6"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>


            <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
              Oops! You’re not connected
            </h1>
            <p className="text-slate-600 dark:text-slate-400 mt-2 text-base">
              To continue, please login and get back on track.
            </p>

            <Button
              variant="default"
              className="mt-6 bg-green-500 hover:bg-green-600 hover:dark:bg-green-700 text-white"
              onClick={() => setOpenModal(true)}
            >
              Connect Wallet
            </Button>
          </div>
        </div>
      </div>

      {openModal && <WalletModal onClose={() => setOpenModal(false)} />}
    </div>
  );
};

export default Disconnected;
