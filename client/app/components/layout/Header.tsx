"use client";
import React, { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "react-toastify";
import { useDisconnect } from "@starknet-react/core";
import ThemeToggle from "../utils/ThemeToggle";
import Categories from "../sections/Categories";

import {
  ChevronDown,
  Menu,
  X,
  User,
  LogOut,
  Settings,
  BarChart3,
} from "lucide-react";
import ConnectModal from "../ui/ConnectWalletModal";
import { useAppContext } from "@/app/context/appContext";
import MarqueeSection from "../sections/marquee";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);
  const [isConnectModal, setIsConnectModal] = useState(false);
  const { address, status } = useAppContext();

  const { disconnect } = useDisconnect();
  const router = useRouter();

  const handleScroll = () => {
    setIsScrolled(window.scrollY > 50);
  };

  useEffect(() => {
    window.addEventListener("scroll", handleScroll);
    return () => {
      window.removeEventListener("scroll", handleScroll);
    };
  }, []);

  useEffect(() => {
    setIsConnected(status === "connected");
  }, [status]);

  const toggleDropdown = () => {
    setIsDropdownOpen((prev) => !prev);
  };

  const connectWalletModal = () => {
    setIsConnectModal(!isConnectModal);
  };

  const handleDisconnect = () => {
    disconnect();
    localStorage.removeItem("connector");
    toast.info("Wallet disconnected");
    setIsDropdownOpen(false);
  };

  return (
    <>
      <header
        className={`w-full fixed top-0 left-0 right-0 z-40 transition-all duration-300 backdrop-blur-lg ${
          isScrolled
            ? "bg-white/90 dark:bg-gray-900/90 shadow-sm"
            : "bg-white/80 dark:bg-gray-900/80"
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div
              className="flex-shrink-0 cursor-pointer flex items-center"
              onClick={() => router.push("/")}
            >
              <Image
                src="/stakcast-logo-2.png"
                alt="Stakcast"
                width={250}
                height={250}
                className="h-[5.5rem] w-auto"
              />{" "}
              {/* <span className="text-green-700 font-bold">Stakcast</span> */}
            </div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              <nav className="flex space-x-6">
                <Link
                  href="/dashboard"
                  className="text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium text-sm transition-colors"
                >
                  Dashboard
                </Link>
                <Link
                  href="/howitworks"
                  className="text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium text-sm transition-colors"
                >
                  How It Works
                </Link>
                {/* <Link
                  href="#about"
                  className="text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium text-sm transition-colors"
                >
                  About Us
                </Link> */}
              </nav>

              <div className="flex items-center space-x-4">
                <ThemeToggle />

                {isConnected ? (
                  <div className="flex items-center space-x-2">
                    <span className="bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 py-1 px-3 rounded-full text-xs font-medium">
                      {address?.slice(0, 4)}...{address?.slice(-4)}
                    </span>

                    <div className="relative">
                      <button
                        type="button"
                        onClick={toggleDropdown}
                        className="flex items-center text-sm focus:outline-none"
                      >
                        <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white">
                          <User className="w-4 h-4" />
                        </div>
                        <ChevronDown
                          className={`ml-1 w-4 h-4 text-gray-500 transition-transform ${
                            isDropdownOpen ? "rotate-180" : ""
                          }`}
                        />
                      </button>

                      {isDropdownOpen && (
                        <div className="absolute right-0 z-50 mt-2 w-48 origin-top-right bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-100 dark:border-gray-700 divide-y divide-gray-100 dark:divide-gray-700">
                          <div className="px-4 py-3">
                            <span className="block text-sm font-medium text-gray-900 dark:text-white truncate">
                              {address?.slice(0, 6)}...{address?.slice(-4)}
                            </span>
                          </div>
                          <ul className="py-1">
                            <li>
                              <Link
                                href="/dashboard"
                                className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                onClick={() => setIsDropdownOpen(false)}
                              >
                                <BarChart3 className="w-4 h-4 mr-2" />
                                Dashboard
                              </Link>
                            </li>
                            <li>
                              <Link
                                href="/settings"
                                className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                                onClick={() => setIsDropdownOpen(false)}
                              >
                                <Settings className="w-4 h-4 mr-2" />
                                Settings
                              </Link>
                            </li>
                            <li>
                              <button
                                className="w-full flex items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 text-left"
                                onClick={handleDisconnect}
                              >
                                <LogOut className="w-4 h-4 mr-2" />
                                Disconnect
                              </button>
                            </li>
                          </ul>
                        </div>
                      )}
                    </div>
                  </div>
                ) : (
                  <button
                    className="bg-gradient-to-r from-green-500 to-green-700 hover:from-blue-600 hover:to-blue-700 text-white px-4 py-1.5 rounded-lg text-sm font-medium transition-all shadow-sm hover:shadow"
                    onClick={connectWalletModal}
                  >
                    Connect Wallet
                  </button>
                )}
              </div>
            </div>

            {/* Mobile Menu Button */}
            <div className="md:hidden flex items-center">
              <ThemeToggle />
              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="ml-3 text-gray-700 dark:text-gray-300 focus:outline-none"
              >
                {isMenuOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Navigation Menu */}
        {isMenuOpen && (
          <div className="md:hidden bg-white dark:bg-gray-900 shadow-lg">
            <nav className="px-4 pt-2 pb-4 space-y-2">
              <Link
                href="/dashboard"
                className="block py-2 text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium"
                onClick={() => setIsMenuOpen(false)}
              >
                Dashboard
              </Link>
              <Link
                href="/howitworks"
                className="block py-2 text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium"
                onClick={() => setIsMenuOpen(false)}
              >
                How It Works
              </Link>
              <Link
                href="#about"
                className="block py-2 text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium"
                onClick={() => setIsMenuOpen(false)}
              >
                About Us
              </Link>

              <div className="pt-2">
                {!isConnected ? (
                  <button
                    className="w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium"
                    onClick={() => {
                      connectWalletModal();
                      setIsMenuOpen(false);
                    }}
                  >
                    Connect Wallet
                  </button>
                ) : (
                  <div className="space-y-2">
                    <div className="bg-gray-100 dark:bg-gray-800 rounded-lg p-3">
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        Connected wallet
                      </p>
                      <p className="text-sm font-medium text-gray-800 dark:text-gray-200">
                        {address?.slice(0, 6)}...{address?.slice(-4)}
                      </p>
                    </div>
                    <button
                      className="w-full flex items-center justify-center gap-2 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/30 text-red-600 dark:text-red-400 px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                      onClick={() => {
                        handleDisconnect();
                        setIsMenuOpen(false);
                      }}
                    >
                      <LogOut className="w-4 h-4" />
                      Disconnect Wallet
                    </button>
                  </div>
                )}
              </div>
            </nav>
          </div>
        )}

        <Categories />
        <MarqueeSection/>
      </header>
      {isConnectModal && (
        <ConnectModal
          onClose={() => {
            setIsConnectModal(false);
          }}
        />
      )}

      {/* This div creates space for the fixed header so content doesn't hide behind it */}

      <div className="h-[80px]"></div>
    
    </>
  );
};

export default Header;
