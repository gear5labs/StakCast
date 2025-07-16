"use client";
import React, { useEffect } from "react";
import { useConnect } from "@starknet-react/core";
import { useAppContext } from "./context/appContext";
import { SessionAccountInterface } from "@argent/invisible-sdk";

export function Providers({ children }: { children: React.ReactNode }) {
  const { status, connectionMode, setAccount } = useAppContext();
  const { connectors, connectAsync } = useConnect({});
  const [loading, setLoading] = React.useState(true);

  useEffect(() => {
    const reconnect = async () => {
      if (connectionMode === "wallet") {
        const LS_connector = localStorage.getItem("connector");
        console.log("attempting to reconnect");
        if (LS_connector && status === "disconnected") {
          const connector = connectors.find((con) => con.id === LS_connector);
          console.log(connector);
          if (connector) {
            try {
              await connectAsync({ connector });
              console.log("Wallet reconnected successfully");
            } catch (error) {
              console.log("Reconnection error:", error);
              localStorage.removeItem("connector");
            }
          }
        }
      } else {
        const LS_session = localStorage.getItem("sessionItem");
        if (LS_session) {
          const sessionItem: SessionAccountInterface = JSON.parse(LS_session);
          setAccount(sessionItem);
        }
      }

      setLoading(false);
    };

    reconnect();
  }, [status, connectAsync, connectors, connectionMode]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 w-full">
        <div className="flex items-center space-x-3 text-gray-600">
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-t-transparent border-gray-400" />
          <span className="text-sm font-medium">Loading wallet...</span>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
