"use client"
import React, { useEffect } from "react";
import { useConnect, useAccount } from "@starknet-react/core";

export function Providers({ children }: { children: React.ReactNode }) {
  const { connectors, connectAsync } = useConnect({});
  const { status } = useAccount();
 
  useEffect(() => {
    const LS_connector = localStorage.getItem("connector");
    
    if (LS_connector && status === 'disconnected') {
      (async () => {
        const connector = connectors.find(
          (con) => con.id === LS_connector
        );
        
        if (connector) {
          try {
            await connectAsync({ connector })
              .then(() => console.log("Wallet reconnected successfully"))
              .catch(err => console.log('Reconnection error:', err));
          } catch (error) {
            console.log("Failed to reconnect wallet:", error);
            // Si falla la reconexión, limpiar el localStorage
            localStorage.removeItem("connector");
          }
        }
      })();
    }
  }, [status, connectAsync, connectors]);

  return <>{children}</>;
}
