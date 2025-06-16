"use client";
import React, { useEffect, useRef, useState } from "react";
import { toast } from "react-toastify";
import { useConnect } from "@starknet-react/core";
import { StarknetkitConnector, useStarknetkitConnectModal } from "starknetkit";
import { X, Wallet, Mail } from "lucide-react";
import { useArgentSdk } from "../utils/invisible-sdk";
import { useAppContext } from "@/app/context/appContext";
import Spinner from "./loading/Spinner";

interface WalletModalProps {
  onClose: () => void;
}

const WalletModal: React.FC<WalletModalProps> = ({ onClose }) => {
  const { setConnectionMode } = useAppContext();
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const modalRef = useRef<HTMLDivElement>(null);

  const { connectAsync, connectors } = useConnect();

  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
    modalTheme: "system",
  });

  const { connect: emailConnect } = useArgentSdk();

  // Handles wallet connection
  const authWalletHandler = async () => {
    setConnectionMode("wallet");
    try {
      setIsLoading(true);
      const { connector } = await starknetkitConnectModal();
      if (!connector) {
        toast.error("No wallet selected");
        return;
      }

      await connectAsync({ connector });
      localStorage.setItem("connector", connector.id);
      toast.success("Wallet connected");
    } catch (error) {
      console.error("Wallet connect error:", error);
      toast.error("Wallet connection failed");
    } finally {
      setIsLoading(false);
    }
  };

  // Handles click outside to close
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        modalRef.current &&
        !modalRef.current.contains(event.target as Node)
      ) {
        onClose();
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div
        ref={modalRef}
        className="relative w-full max-w-sm p-8 bg-white dark:bg-gray-900 rounded-2xl shadow-2xl text-center transform transition-all duration-300 ease-in-out"
      >
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex justify-center mb-6">
          <div className="w-16 h-16 bg-gradient-to-br from-green-400 to-blue-500 rounded-full flex items-center justify-center">
            <div className="w-14 h-14 bg-white dark:bg-gray-800 rounded-full flex items-center justify-center">
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M18 8H17V6C17 3.24 14.76 1 12 1C9.24 1 7 3.24 7 6V8H6C4.9 8 4 8.9 4 10V20C4 21.1 4.9 22 6 22H18C19.1 22 20 21.1 20 20V10C20 8.9 19.1 8 18 8ZM12 17C10.9 17 10 16.1 10 15C10 13.9 10.9 13 12 13C13.1 13 14 13.9 14 15C14 16.1 13.1 17 12 17ZM15 8H9V6C9 4.34 10.34 3 12 3C13.66 3 15 4.34 15 6V8Z"
                  fill="url(#paint0_linear)"
                />
                <defs>
                  <linearGradient
                    id="paint0_linear"
                    x1="4"
                    y1="1"
                    x2="20"
                    y2="22"
                    gradientUnits="userSpaceOnUse"
                  >
                    <stop stopColor="#4ADE80" />
                    <stop offset="1" stopColor="#3B82F6" />
                  </linearGradient>
                </defs>
              </svg>
            </div>
          </div>
        </div>

        <h2 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">
          Welcome to Stakcast
        </h2>

        <p className="text-gray-500 dark:text-gray-400 mb-8">
          Choose how you&apos;d like to sign in
        </p>

        <div className="space-y-4">
          <button
            onClick={async () => {
              await authWalletHandler();
              onClose();
            }}
            className="w-full py-4 px-6 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white font-semibold rounded-xl shadow-md hover:shadow-lg transition-all flex items-center justify-center space-x-2"
          >
            <Wallet className="w-5 h-5" />
            <span>{isLoading ? <Spinner /> : "Connect Wallet"}</span>
          </button>

          <div className="relative flex items-center justify-center my-6">
            <div className="absolute border-t border-gray-200 dark:border-gray-700 w-full"></div>
            <div className="absolute bg-white dark:bg-gray-900 px-4 text-sm text-gray-500">
              OR
            </div>
          </div>

          <button
            onClick={async () => {
              try {
                setIsLoading(true);
                await emailConnect();
                setConnectionMode("email");
                toast.success("Email connected");
                onClose();
              } catch (error) {
                console.error("Email connect error:", error);
                toast.error("Email connection failed");
              } finally {
                setIsLoading(false);
              }
            }}
            className="w-full py-4 px-6 border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 font-semibold rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 shadow-sm hover:shadow transition-all flex items-center justify-center space-x-2"
          >
            <Mail className="w-5 h-5" />
            <span>{isLoading ? <Spinner /> : "Continue with Email"}</span>
          </button>
        </div>

        <p className="mt-6 text-xs text-gray-500 dark:text-gray-400">
          By continuing, you agree to Stakcast&apos;s Terms of Service and
          Privacy Policy.
        </p>
      </div>
    </div>
  );
};

export default WalletModal;
