"use client";
// import type { Metadata } from "next";
import { Manrope } from "next/font/google";
// import Header from "./components/layout/Header";
import "./globals.css";
import "primereact/resources/themes/lara-light-cyan/theme.css";

// import { StarknetProvider } from "./components/utils/Provider";
// import { AppProvider } from "./context/appContext";
import { Suspense } from "react";

import { StarknetConfig, publicProvider } from "@starknet-react/core";
import { mainnet, sepolia } from "@starknet-react/chains";
// import { connectors } from "@/components/utils/connectors";
import "./globals.css";
import { connectors } from "./components/utils/connectors";
import { Bounce, ToastContainer } from "react-toastify";
import { ThemeProvider } from "./context/ThemeContext";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
  
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const chains = [mainnet, sepolia];
  const providers = publicProvider();

  return (
    <html lang="en">
      <body
        className={`${manrope.className} antialiased bg-[white] text-gray-600`}
      >
        <Suspense>
        <ToastContainer
        position="bottom-right"
        autoClose={5000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick={false}
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="dark"
        transition={Bounce}
      />
          <StarknetConfig
            chains={chains}
            provider={providers}
            connectors={connectors}
          >
            <ThemeProvider>{children}</ThemeProvider>
          </StarknetConfig>
        </Suspense>
      </body>
    </html>
  );
}
