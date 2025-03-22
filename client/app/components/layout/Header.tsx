"use client";
import React, { useState } from "react";
import Connector from "../utils/Connector";
import Image from "next/image";
import Categories from "../sections/Categories";
import Link from "next/link";
import { useAppContext } from "@/app/context/appContext";
import { useRouter } from "next/navigation";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [walletModal, setWalletModal] = useState<boolean>(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const { status, address, disconnectWallet } = useAppContext();
  const router = useRouter();

  // Compute isConnected based on status
  const isConnected = status === "connected";

  const toggleMenu = () => {
    setIsMenuOpen((prev) => !prev);
  };

  const toggleModal = () => {
    setWalletModal((prev) => !prev);
  };

  const toggleDropdown = () => {
    setIsDropdownOpen((prev) => !prev);
  };

  return (
    <header className="border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex-shrink-0 cursor-pointer" onClick={() => router.push("/")}>
            <Image src="/logo.svg" alt="Stakcast" width={170} height={170} />
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

                {/* User Profile Dropdown */}
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
                            onClick={() => {
                              disconnectWallet();
                              setIsDropdownOpen(false);
                            }}
                          >
                            Sign out
                          </button>
                        </li>
                      </ul>
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <button
                className="bg-yellow-600 text-white hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium"
                onClick={toggleModal}
              >
                Connect Wallet
              </button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <div className="md:hidden">
            <button
              onClick={toggleMenu}
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
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
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
            <Link href="/howitworks" className="block hover:text-blue-400">
              How It Works
            </Link>
            <a href="#about" className="block hover:text-blue-400">
              About Us
            </a>
            { !isConnected && (
              <button
                className="w-full bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded text-sm font-medium text-white"
                onClick={toggleModal}
              >
                Connect Wallet
              </button>
            )}
          </nav>
        </div>
      )}

      {/* Wallet Connector Modal */}
      {walletModal && (
        <div>
          <Connector />
        </div>
      )}

      <Categories />
    </header>
  );
};

export default Header;
