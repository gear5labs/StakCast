"use client";
import React, { useEffect, useState } from "react";

import SEO from "../../../../shared/components/Seo"; 
import seoData from "../../../../shared/components/seoData.json"; 


import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "react-toastify";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import { StarknetkitConnector, useStarknetkitConnectModal } from "starknetkit";
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


const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isConnected, setIsConnected] = useState(false);

  const { address, status } = useAccount();
  const { connectAsync, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  // const { status, address } = useAppContext();

  // const [walletModal, setWalletModal] = useState<boolean>(false);

  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  const { address, status } = useAccount();
  const { connectAsync, connectors } = useConnect();
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

  const router = useRouter();



  const toggleDropdown = () => {
    setIsDropdownOpen((prev) => !prev);
  };


  // Extract SEO data for the header
  const { title, description, keywords, image, url } = seoData.Header;


  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
    modalTheme: "system",
  });

  const authWalletHandler = async () => {
    const { connector } = await starknetkitConnectModal();
    if (!connector) return;

    try {
      await connectAsync({ connector });
      toast.success("Wallet connected");
      localStorage.setItem("connector", connector.id);
    } catch (_e) {
      console.log(_e)
      toast.error("Connection rejected");
    }
  };

  const handleDisconnect = () => {
    disconnect();
    localStorage.removeItem("connector");
    toast.info("Wallet disconnected");
    setIsDropdownOpen(false);
  };

  return (
    <>

      {/* SEO Component: Set meta tags for the header, enhancing discoverability */}
      <SEO title={title} description={description} keywords={keywords} image={image} url={url} />

      <header
        className={`border-b border-gray-100 w-full fixed top-0 left-0 right-0 z-10 transition-all duration-300 ${
          isScrolled ? "bg-white dark:bg-slate-950" : "bg-white dark:bg-slate-950"

      <header
        className={`w-full fixed top-0 left-0 right-0 z-40 transition-all duration-300 backdrop-blur-lg ${
          isScrolled
            ? "bg-white/90 dark:bg-gray-900/90 shadow-sm"
            : "bg-white/80 dark:bg-gray-900/80"

        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">

            <div className="flex-shrink-0 cursor-pointer" onClick={() => router.push("/")}>
              <Image src="/logo.svg" alt="StakCast logo - A decentralized prediction platform" width={170} height={170} />
            </div>

            <div className="flex gap-2">
              <nav className="hidden md:flex space-x-6 self-center">
                <Link href="/dashboard" className="hover:text-blue-400">Dashboard</Link>
                <Link href="/howitworks" className="hover:text-blue-400">How It Works</Link>
                <a href="#about" className="hover:text-blue-400">About Us</a>
              </nav>
              <ThemeToggle />
            </div>

            <div className="hidden md:block">
              {isConnected ? (
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
                  <div className="relative">
                    <button
                      type="button"
                      onClick={toggleDropdown}
                      className="flex text-sm bg-gray-800 rounded-full focus:ring-4 focus:ring-gray-300"
                      id="user-menu-button"
                      aria-expanded={isDropdownOpen}
                    >
                      <span className="sr-only">Open user menu</span>
                      <Image
                        src="/logo.svg"
                        alt="user photo"
                        width={32}
                        height={32}
                        className="w-8 h-8 rounded-full"
                      />
                    </button>

                  {isDropdownOpen && (
                    <div className="absolute right-0 z-50 mt-2 w-48 bg-white divide-y divide-gray-100 rounded-lg shadow-sm">
                      <div className="px-4 py-3">
                        <span className="block text-sm text-gray-900">Bonnie Green</span>
                        <span className="block text-sm text-gray-500 truncate">example@email.com</span>
                      </div>
                      <ul className="py-2" aria-labelledby="user-menu-button">
                        <li>
                          <a href="#" className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            Dashboard
                          </a>
                        </li>
                        <li>
                          <a href="#" className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            Settings
                          </a>
                        </li>
                        <li>
                          <a href="#" className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            Earnings
                          </a>
                        </li>
                        <li>
                          <button
                            className="block px-4 py-2 text-sm text-red-700 hover:bg-gray-100"
                            onClick={handleDisconnect}
                          >
                            Sign out
                          </button>
                        </li>
                      </ul>
                    </div>
                  )}
                </div>

            {/* Logo */}
            <div
              className="flex-shrink-0 cursor-pointer flex items-center"
              onClick={() => router.push("/")}
            >
              <Image
                src="/stakcast-logo.png"
                alt="Stakcast"
                width={230}
                height={230}
                className="h-10 w-auto"
              />{" "}
              <span className="text-green-700 font-bold">Stakcast</span>
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
                <Link
                  href="#about"
                  className="text-gray-700 dark:text-gray-300 hover:text-blue-500 dark:hover:text-blue-400 font-medium text-sm transition-colors"
                >
                  About Us
                </Link>
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
                    className="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-4 py-1.5 rounded-lg text-sm font-medium transition-all shadow-sm hover:shadow"
                    onClick={authWalletHandler}
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

                Disconnect Wallet
              </button>
            )}
          </nav>
        </div>
      )}


        {/* Wallet Connector Modal */}
        {/* {walletModal && (
          <div>
            <Connector />
          </div>
        )} */}

        <Categories />
      </header>

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
                      authWalletHandler();
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
      </header>

      {/* This div creates space for the fixed header so content doesn't hide behind it */}
      <div className="h-[80px]"></div>

    </>
  );
};

export default Header;