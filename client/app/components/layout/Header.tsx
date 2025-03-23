"use client";
import React, { useEffect, useState } from "react";
/* 
import {Connectors} from "../utils/connectors/index";
*/
import Image from "next/image";
import Categories from "../sections/Categories";
import Link from "next/link";

import { useRouter } from "next/navigation";
import { useAccount, useConnect } from "@starknet-react/core";
/*  import { WalletModal } from "../ui";*/
import { StarknetkitConnector, useStarknetkitConnectModal } from "starknetkit";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
 /* const [walletModal, setWalletModal] = useState<boolean>(false);*/
  const [isConnected, setIsConnected] = useState(false);
  const { address, status } = useAccount();
  const { connectAsync, connectors } = useConnect();
  useEffect(() => {
    if (status === "connected") {
      setIsConnected(true);
    }
  }, [status, isConnected]);
  const router = useRouter();

  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
    modalTheme: "dark",
  });

  const authWalletHandler = async () => {
    const { connector } = await starknetkitConnectModal();
    if (!connector) {
      return;
    }
    await connectAsync({ connector });
  };
  return (
    <header className="border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex-shrink-0">
            <Image
              src="/logo.svg"
              alt="Stakcast"
              width={170}
              height={170}
              onClick={() => router.push("/")}
            />
          </div>

          {/* Navigation Links */}
          <nav className="hidden md:flex space-x-6">
            <Link href="/dashboard" className="hover:text-blue-400">
              Dashboard
            </Link>
            <Link href="/howitworks" className="hover:text-blue-400">
              How It Works
            </Link>
            <a href="#about" className="hover:text-blue-400">
              About Us
            </a>
          </nav>

          {/* Wallet Section */}
          <div className="hidden md:block">
            {status === "connected" ? (
              <div className="flex items-center space-x-2">
                <span className="text-sm text-gray-600">
                  {address?.slice(0, 6)}...{address?.slice(-4)}
                </span>
                <Link
                  href="/dashboard"
                  className="bg-blue-600 text-white hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium"
                >
                  Dashboard
                </Link>
                {/* profile */}
                <div className="px-5 py-5 rounded-full bg-blue-200"></div>
              </div>
            ) : (
              <button
                className="bg-yellow-600 text-white hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium"
                onClick={authWalletHandler}
              >
                Connect Wallet
              </button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <div className="md:hidden">
            <button
             onClick={()=> setIsMenuOpen(!isMenuOpen)}
              className="text-gray-300 hover:text-white focus:outline-none focus:ring-2 focus:ring-white"
            >
              <svg
                className="h-6 w-6"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                {isMenuOpen ? (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                ) : (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                )}
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="md:hidden">
          <nav className="px-2 py-4 space-y-2">
            <Link href="/dashboard" className="block hover:text-blue-400">
              Dashboard
            </Link>
            <a href="/howitworks" className="block hover:text-blue-400">
              How It Works
            </a>
            <a href="#about" className="block hover:text-blue-400">
              About Us
            </a>
            {status !== "connected" && (
              <button
                className="w-full bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium text-white"
                onClick={authWalletHandler}
              >
                Connect Wallet
              </button>
            )}
          </nav>
        </div>
      )}

      <Categories />
    </header>
  );
};

export default Header;
