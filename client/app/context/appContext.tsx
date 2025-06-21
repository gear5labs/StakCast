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
import { useAccount, useBalance, useContract } from "@starknet-react/core";
import { SessionAccountInterface } from "@argent/invisible-sdk";
import {
  SKTokenAddress,
  STRKTokenAddress,
} from "../components/utils/constants";
import { AccountInterface } from "starknet";
import { Token } from "../components/sections/PurchaseSection";
import erc20Abi from "../abis/token";

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
  skPrice: number | null;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const getInitialConnectionMode = (): "email" | "wallet" => {
  if (typeof window === "undefined") return "wallet";
  const stored = localStorage.getItem("connectionMode");
  return stored === "email" ? "email" : "wallet";
};

export function AppProvider({ children }: { children: ReactNode }) {
  const { account, address: walletAddress, isConnected } = useAccount();

  const [sessionAccount, setAccount] = useState<
    SessionAccountInterface | undefined
  >(undefined);
  const [connectionModeState, setConnectionModeState] = useState<
    "email" | "wallet"
  >(getInitialConnectionMode());
  const [selectedToken, setSelectedToken] = useState<Token>("STRK");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [tokenPrice, setTokenPrice] = useState<number | null>(null);
  const [skPrice, setSkPrice] = useState<number | null>(null);

  const { contract } = useContract({ address: SKTokenAddress, abi: erc20Abi });

  // Use sessionAccount address if present
  const address = sessionAccount ? sessionAccount.address : walletAddress;

  const { data, isFetching } = useBalance({
    token: STRKTokenAddress,
    address: address as `0x${string}`,
  });

  const balance = isFetching
    ? "loading..."
    : data?.formatted
    ? `${parseFloat(data.formatted).toFixed(2)} ${data.symbol}`
    : "";

  const balanceValue = parseFloat(data?.formatted || "0");
  const balanceInUSD =
    tokenPrice !== null
      ? `$${(balanceValue * tokenPrice).toFixed(2)}`
      : "loading...";

  const status = isConnected ? "connected" : "disconnected";

  const setConnectionMode = (mode: "email" | "wallet") => {
    localStorage.setItem("connectionMode", mode);
    setConnectionModeState(mode);
  };

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
        setTokenPrice(null);
      }
    }

    fetchPrice();
    const interval = setInterval(fetchPrice, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    async function fetchSKPrice() {
      if (contract && address) {
        try {
          const result = (await contract.call("balance_of", [
            address,
          ])) as unknown as { balance: string };

          const parsed = parseFloat(result.balance);
          const normalized = parsed / 1e18;
          console.log(normalized, "SK Balance Parsed");
          setSkPrice(isNaN(normalized) ? null : normalized);
        } catch (err) {
          console.error("Failed to fetch SK token balance:", err);
          setSkPrice(null);
        }
      }
    }

    fetchSKPrice();
  }, [contract, address]);

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
        skPrice,
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
