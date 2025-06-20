"use client";

import {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
  SetStateAction,
  Dispatch,
} from "react";
import { useAccount, useBalance } from "@starknet-react/core";
import { SessionAccountInterface } from "@argent/invisible-sdk";
import { STRKTokenAddress } from "../components/utils/constants";
import { AccountInterface } from "starknet";
import { Token } from "../components/sections/PurchaseSection";

interface AppContextType {
  balance: string;
  balanceInUSD: string;
  address: `0x${string}` | undefined;
  sessionAccount: SessionAccountInterface | undefined;
  status: string;
  account: AccountInterface | undefined;
  setAccount: Dispatch<SetStateAction<SessionAccountInterface | undefined>>;
  setConnectionMode: (mode: "email" | "wallet") => void;
  connectionMode: "email" | "wallet";
  selectedToken: Token;
  setSelectedToken: Dispatch<SetStateAction<Token>>;
  searchQuery: string;
  setSearchQuery: Dispatch<SetStateAction<string>>;
  tokenPrice: number | null;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const getInitialConnectionMode = (): "email" | "wallet" => {
  if (typeof window === "undefined") return "wallet";
  const stored = localStorage.getItem("connectionMode");
  return stored === "email" ? "email" : "wallet";
};

export function AppProvider({ children }: { children: ReactNode }) {
  let { address } = useAccount();
  const { account, isConnected } = useAccount();

  const [sessionAccount, setAccount] = useState<
    SessionAccountInterface | undefined
  >();

  const [connectionModeState, setConnectionModeState] = useState<
    "email" | "wallet"
  >(getInitialConnectionMode());

  const [selectedToken, setSelectedToken] = useState<Token>("STRK");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [tokenPrice, setTokenPrice] = useState<number | null>(null);

  const setConnectionMode = (mode: "email" | "wallet") => {
    localStorage.setItem("connectionMode", mode);
    setConnectionModeState(mode);
  };

  // Override address with sessionAccount address if available
  address = sessionAccount ? sessionAccount.address : address;

  const { data, isFetching } = useBalance({
    token: STRKTokenAddress,
    address: address as "0x",
  });

  const balance = isFetching
    ? "loading..."
    : data?.formatted
    ? `${parseFloat(data.formatted).toFixed(2)} ${data.symbol}`
    : "";

  // Fetch token price from CoinGecko
  useEffect(() => {
    async function fetchPrice() {
      try {
        const res = await fetch(
          "https://api.coingecko.com/api/v3/simple/price?ids=starknet&vs_currencies=usd"
        );
        const data = await res.json();
        setTokenPrice(data?.starknet?.usd ?? null);
      } catch (err) {
        console.error("Failed to fetch STRK price in USD:", err);
      }
    }

    fetchPrice();
    const interval = setInterval(fetchPrice, 5 * 60 * 1000); // every 5 min
    return () => clearInterval(interval);
  }, []);

  // Convert balance to USD
  const balanceValue = parseFloat(balance);
  const balanceInUSD =
    !isNaN(balanceValue) && tokenPrice !== null
      ? `$${(balanceValue * tokenPrice).toFixed(2)}`
      : "loading...";

  const status = isConnected ? "connected" : "disconnected";

  return (
    <AppContext.Provider
      value={{
        balance,
        balanceInUSD,
        address,
        sessionAccount,
        status,
        account,
        setAccount,
        connectionMode: connectionModeState,
        setConnectionMode,
        selectedToken,
        setSelectedToken,
        searchQuery,
        setSearchQuery,
        tokenPrice,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error("useAppContext must be used within an AppProvider");
  }
  return context;
}
