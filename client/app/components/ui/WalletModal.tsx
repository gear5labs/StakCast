"use client";
import React from "react";
import { useConnect } from "@starknet-react/core";
// import { useAppContext } from "@/app/context/appContext";
// import { useAccount, useDisconnect } from "@starknet-react/core";
import { StarknetkitConnector, useStarknetkitConnectModal } from "starknetkit";
import { toast } from "react-toastify";

const WalletModal = () => {
  const { connectAsync, connectors } = useConnect()

  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
    modalTheme: "light",
  })
  return (
    <div className="p-6 max-w-md mx-auto  rounded-xl shadow-md space-y-4">
      <h2 className="text-xl font-semibold text-center">Connect Your Wallet</h2>
      <div className="space-y-2">
        {/* {connectors.map((connector, index) => (
          <div
            key={`connectWalletModal${connector.id}${index}`}
            onClick={() => connectWallet(connector)}
            className="p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-300 hover:border-gray-400 transition"
          >
            <p className="text-center font-medium">
              {connector.id.charAt(0).toUpperCase() + connector.id.slice(1)}
            </p>
          </div>
        ))} */}
      </div>
      <button
        className="w-full justify-center"
        onClick={async () => {
          const { connector } = await starknetkitConnectModal();
          if (!connector) {
            console.log("User rejected to connect")
            return;
          }
          await connectAsync({ connector })
            .then(() => {
              console.log("success");
              toast.success("Wallet conectada");
              // Guardar el ID del conector en localStorage
              localStorage.setItem("connector", connector.id);
            })
            .catch((e) => {
              console.log(e);
              toast.error("Error al conectar la wallet");
            });
        }}
      >
       connect wallet
      </button>
    </div>
  );
};

export default WalletModal;
