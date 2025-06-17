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

  if (loading) return <div>Loading wallet...</div>;

  return <>{children}</>;
}
