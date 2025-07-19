import React from "react";
import { BackButton } from "../components/ui/backButton";

const HowItWorks: React.FC = () => {
  return (
    <section className="bg-white dark:bg-black py-24 px-6">
      <div className="max-w-4xl mx-auto">
        <BackButton />
        <div className="mb-20">
          <h2 className="text-4xl md:text-5xl font-light text-black dark:text-white mb-4">
            How Stakcast Works
          </h2>
          <p>
            For more information , contact us at{" "}
            <a href="mailto:">contact@stakcast.com</a>
          </p>
          <div className="w-16 h-px bg-black dark:bg-white"></div>
        </div>

        <div className="mb-24">
          <p className="text-lg text-gray-600 dark:text-gray-400 leading-relaxed mb-8">
            Stakcast is an onchain prediction market platform on Starknet where
            users can trade on markets and earn rewards. Leveraging the power of
            Starknet for scalability and security, Stakcast ensures seamless
            user experiences while maintaining a trustless environment.
          </p>
          <p className="text-lg text-gray-600 dark:text-gray-400 leading-relaxed">
            At the core of Stakcast&apos;s validation process are dedicated
            market validators who ensure accurate and transparent resolution of
            prediction markets. The platform offers both traditional Web3 access
            and simplified onboarding for non-crypto users.
          </p>
        </div>

        <div className="space-y-16 mb-24">
          <div className="flex items-start space-x-8">
            <div className="text-6xl font-extralight text-gray-200 dark:text-gray-800 leading-none">
              01
            </div>
            <div className="flex-1 pt-2">
              <h3 className="text-2xl font-medium text-black dark:text-white mb-4">
                Explore and Join Markets
              </h3>
              <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
                Users can explore active prediction markets and participate in
                those that interest them. If you want to create markets, you can
                apply to become a market creator through our application
                process. Once approved, market creators can define questions and
                set expiration dates. All created markets must then be approved
                by validators to ensure consistency and reduce spam before going
                live.
              </p>
            </div>
          </div>

          <div className="flex items-start space-x-8">
            <div className="text-6xl font-extralight text-gray-200 dark:text-gray-800 leading-none">
              02
            </div>
            <div className="flex-1 pt-2">
              <h3 className="text-2xl font-medium text-black dark:text-white mb-4">
                Trade Seamlessly
              </h3>
              <p className="text-gray-600 dark:text-gray-400 leading-relaxed mb-4">
                Stakcast operates as a paramutuel market where all stakes are
                pooled together. Users can place positions using:
              </p>
              <ul className="space-y-2 text-gray-600 dark:text-gray-400 mb-4">
                <li>
                  <span className="font-medium text-black dark:text-white">
                    STRK tokens
                  </span>{" "}
                  — The native Starknet token
                </li>
                <li>
                  <span className="font-medium text-black dark:text-white">
                    SK tokens
                  </span>{" "}
                  — Stakcast&apos;s native token minted on Starknet
                </li>
                <li>
                  <span className="font-medium text-black dark:text-white">
                    Fiat option
                  </span>{" "}
                  — For non-Web3 enthusiasts who prefer traditional payment
                  methods
                </li>
              </ul>
              <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
                The final odds are determined by the total distribution of
                stakes across all outcomes when the market closes.
              </p>
            </div>
          </div>

          {/* Step 3 */}
          <div className="flex items-start space-x-8">
            <div className="text-6xl font-extralight text-gray-200 dark:text-gray-800 leading-none">
              03
            </div>
            <div className="flex-1 pt-2">
              <h3 className="text-2xl font-medium text-black dark:text-white mb-4">
                Automated Resolution
              </h3>
              <p className="text-gray-600 dark:text-gray-400 leading-relaxed mb-4">
                Once a market expires, resolution happens through:
              </p>
              <ul className="space-y-2 text-gray-600 dark:text-gray-400">
                <li>
                  <span className="font-medium text-black dark:text-white">
                    Oracle networks
                  </span>{" "}
                  — Most markets resolve automatically using trusted data feeds
                </li>
                <li>
                  <span className="font-medium text-black dark:text-white">
                    Validator consensus
                  </span>{" "}
                  — Complex markets requiring interpretation are resolved by our
                  decentralized validator network
                </li>
              </ul>
            </div>
          </div>

          {/* Step 4 */}
          <div className="flex items-start space-x-8">
            <div className="text-6xl font-extralight text-gray-200 dark:text-gray-800 leading-none">
              04
            </div>
            <div className="flex-1 pt-2">
              <h3 className="text-2xl font-medium text-black dark:text-white mb-4">
                Instant Payouts
              </h3>
              <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
                After market resolution, winnings are distributed automatically
                from the total pool. Winners share the entire pool
                proportionally based on their stakes. Users can withdraw in
                their preferred method based on how they initially funded their
                account.
              </p>
            </div>
          </div>
        </div>

        {/* Divider */}
        <div className="w-full h-px bg-gray-200 dark:bg-gray-800 mb-24"></div>

        {/* Feature Sections */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-16 mb-24">
          {/* Fiat Integration */}
          <div>
            <h3 className="text-2xl font-medium text-black dark:text-white mb-6">
              Fiat Option for Non-Web3 Users
            </h3>
            <p className="text-gray-600 dark:text-gray-400 leading-relaxed mb-6">
              For users who aren&apos;t crypto enthusiasts, Stakcast offers:
            </p>
            <ul className="space-y-3 text-gray-600 dark:text-gray-400">
              <li>
                <span className="font-medium text-black dark:text-white">
                  Fiat deposits
                </span>{" "}
                — Use credit cards or bank transfers to participate
              </li>
              <li>
                <span className="font-medium text-black dark:text-white">
                  Account abstraction
                </span>{" "}
                — We handle all blockchain interactions behind the scenes
              </li>
              <li>
                <span className="font-medium text-black dark:text-white">
                  Simplified interface
                </span>{" "}
                — No need to understand wallets, gas fees, or transaction hashes
              </li>
              <li>
                <span className="font-medium text-black dark:text-white">
                  Fiat withdrawals
                </span>{" "}
                — Cash out winnings directly to your bank account
              </li>
              <li>
                <span className="font-medium text-black dark:text-white">
                  Transparent conversion
                </span>{" "}
                — Fiat is converted to stablecoins onchain, but users see
                everything in their local currency
              </li>
            </ul>
          </div>

          {/* Authentication */}
          <div>
            <h3 className="text-2xl font-medium text-black dark:text-white mb-6">
              Two Ways to Access
            </h3>
            <p className="text-gray-600 dark:text-gray-400 leading-relaxed mb-6">
              Choose your preferred method:
            </p>
            <ul className="space-y-3 text-gray-600 dark:text-gray-400">
              <li>
                <span className="font-medium text-black dark:text-white">
                  Google sign-up
                </span>{" "}
                — Create an account with Google authentication - we handle all
                the blockchain complexity through account abstraction
              </li>
              <li>
                <span className="font-medium text-black dark:text-white">
                  Web3 wallet
                </span>{" "}
                — Connect your existing Starknet wallet for full control and
                direct interaction with the protocol
              </li>
            </ul>
          </div>
        </div>

        {/* Closing */}
        <div className="text-center">
          <p className="text-lg text-gray-600 dark:text-gray-400 leading-relaxed max-w-2xl mx-auto">
            This approach caters to both crypto-native users and those who
            prefer traditional experiences, without compromising on security or
            decentralization.
          </p>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
