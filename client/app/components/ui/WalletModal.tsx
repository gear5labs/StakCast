"use client";
import React from "react";
import { useConnect } from "@starknet-react/core";
import { StarknetkitConnector, useStarknetkitConnectModal } from "starknetkit";

import SEO from "../../../../shared/components/Seo"; 
import seoData from "../../../../shared/components/seoData.json"; 

const WalletModal = () => {
  const { connectAsync, connectors } = useConnect();
  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
    modalTheme: "light",
  });

  return (
    <>
      <SEO
        title={seoData.walletModal.title} 
        description={seoData.walletModal.description} 
        keywords={seoData.walletModal.keywords} 
      />
      <div 
        className="p-6 max-w-md mx-auto rounded-xl shadow-md space-y-4" 
        role="dialog" 
        aria-labelledby="wallet-modal-title" 
        aria-modal="true"
      >
        <h2 id="wallet-modal-title" className="text-xl font-semibold text-center">Connect Your Wallet</h2>
        <div className="space-y-2">
          {/* Commented out for now */}
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
              console.log("User rejected to connect");
              return;
            }
            await connectAsync({ connector }).then(() => console.log("success")).catch((e) => console.log(e));
          }}
        >
          Connect Wallet
        </button>
      </div>
    </>
  );
};

export default WalletModal;