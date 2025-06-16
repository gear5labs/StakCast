"use client";
import {
  createContext,
  useContext,
  useState,
  ReactNode,
  SetStateAction,
  Dispatch,
} from "react";
import { useAccount, useBalance } from "@starknet-react/core";
import { SessionAccountInterface } from "@argent/invisible-sdk";
import { STRKTokenAddress } from "../components/utils/constants";
import { AccountInterface } from "starknet";

interface AppContextType {
  balance: string;
  address: `0x${string}` | undefined;
  sessionAccount: SessionAccountInterface | undefined;
  status: string;
  account: AccountInterface | undefined;
  setAccount: Dispatch<SetStateAction<SessionAccountInterface | undefined>>;
  setConnectionMode: (mode: "email" | "wallet") => void;
  connectionMode: "email" | "wallet";
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const getInitialConnectionMode = (): "email" | "wallet" => {
  if (typeof window === "undefined") return "wallet";
  const stored = localStorage.getItem("connectionMode");
  return stored === "email" ? "email" : "wallet";
};

export function AppProvider({ children }: { children: ReactNode }) {
  let { address} = useAccount();
  const { account, isConnected } = useAccount();
  const [connectionModeState, setConnectionModeState] = useState<
    "email" | "wallet"
  >(getInitialConnectionMode());

  const setConnectionMode = (mode: "email" | "wallet") => {
    localStorage.setItem("connectionMode", mode);
    setConnectionModeState(mode);
  };

  const [sessionAccount, setAccount] = useState<
    SessionAccountInterface | undefined
  >();

  address = sessionAccount ? sessionAccount.address : address;
  console.log(sessionAccount);
  const { data, isFetching } = useBalance({
    token: STRKTokenAddress,
    address: address as "0x",
  });

  const balance = isFetching
    ? "loading..."
    : data?.formatted
    ? `${parseFloat(data.formatted).toFixed(2)} ${data.symbol}`
    : "";

  const status = isConnected ? "connected" : "disconnected";

  return (
    <AppContext.Provider
      value={{
        address,
        status,
        sessionAccount,
        balance,
        setAccount,
        account,
        connectionMode: connectionModeState,
        setConnectionMode,
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
