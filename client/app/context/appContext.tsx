"use client";
import { createContext, useContext } from "react";
import { Toast } from "primereact/toast";
import { useRef } from "react";
import {
  useAccount,
  useBalance,
} from "@starknet-react/core";
interface AppContextType {
  showToast: (
    severity: "success" | "error" | "info",
    summary: string,
    detail: string
  ) => void;
  address?: string;
  status: string;
  balance?: string | React.ReactNode;
  contactAddress?: string;
}
const AppContext = createContext<AppContextType | undefined>(undefined);
export function AppProvider({ children }: { children: React.ReactNode }) {
  const toast = useRef<Toast>(null);
  const { address, status } = useAccount();
  const { data, isLoading } = useBalance({
    token: "0x04718f5a0Fc34cC1AF16A1cdee98fFB20C31f5cD61D6Ab07201858f4287c938D",
    address: address as "0x",
  });
  const balance =
    isLoading || !data ? (
      <p>Loading...</p>
    ) : (
      `${parseFloat(data.formatted).toFixed(2)} STRK`
    );
  const showToast = (
    severity: "success" | "error" | "info",
    summary: string,
    detail: string
  ) => {
    toast.current?.show({ severity, summary, detail });
  };
  const contactAddress =
    "0x02a3cb3bbbe186b59ba4ee6ce1227c284043be42dc46e84115e4587754a89c04";

  return (
    <AppContext.Provider
      value={{
        showToast,
        address,
        status,
        balance,
        contactAddress,
      }}
    >
      <Toast ref={toast} />
      {children}
    </AppContext.Provider>
  );
}

export const useAppContext = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error("useAppContext must be used within an AppProvider");
  }
  return context;
};
