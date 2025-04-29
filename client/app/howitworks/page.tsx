import React from "react";
import SEO from "../../../shared/components/Seo"; 
import seoData from "../../../shared/components/seoData.json"; 

const HowItWorks: React.FC = () => {
  return (
    <section className="bg-gray-50 dark:bg-slate-950 py-12 px-6">
      {/* SEO Component: Set meta tags for the How It Works section */}
      <SEO
        title={seoData.howItWorks.title}
        description={seoData.howItWorks.description}
        keywords={seoData.howItWorks.keywords}
      />
      
      <div className="max-w-5xl mx-auto">
        <h2 className="text-3xl font-bold text-center text-gray-800 dark:text-white mb-6">
          How Stakcast Works
        </h2>

        {/* Overview */}
        <div className="mb-8">
          <p className="text-gray-700 dark:text-white text-lg leading-relaxed">
            Stakcast is a decentralized prediction market platform where users
            can create, trade, and resolve markets. Leveraging the power of
            StarkNet for scalability and security, Stakcast ensures seamless
            user experiences while maintaining a trustless environment.
          </p>
        
          <p className="text-gray-700 dark:text-white text-lg leading-relaxed mt-4">
            At the core of Stakcast’s validation process are intelligent agents
            built on{" "}
            <a
              href="https://www.atoma.network"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 underline"
            >
              Atoma
            </a>
            , which uses Trusted Execution Environments (TEEs) for secure
            computation and reliable data validation. This ensures that market
            outcomes are validated transparently and accurately, without the
            need for centralized authorities.
          </p>
        </div>

        {/* Step-by-step Explanation */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Step 1 */}
          <div className="bg-white dark:bg-slate-950 shadow-md rounded-lg p-6">
            <h3 className="text-xl font-bold text-gray-800 dark:text-white mb-2">
              1. Create or Join a Market
            </h3>
            <p className="text-gray-700 dark:text-white leading-relaxed">
              Users can create prediction markets by defining a question,
              setting an expiration date, and providing initial liquidity.
              Alternatively, you can explore and participate in markets created
              by others.
            </p>
          </div>

          {/* Step 2 */}
          <div className="bg-white dark:bg-slate-950 shadow-md rounded-lg p-6">
            <h3 className="text-xl font-bold text-gray-800 dark:text-white mb-2">
              2. Trade in Real-Time
            </h3>
            <p className="text-gray-700 dark:text-white leading-relaxed">
              Stakcast enables real-time trading on markets, allowing users to
              buy and sell positions based on their predictions. The prices
              dynamically adjust based on supply and demand, reflecting the
              probability of each outcome.
            </p>
          </div>

          {/* Step 3 */}
          <div className="bg-white dark:bg-slate-950 shadow-md rounded-lg p-6">
            <h3 className="text-xl font-bold text-gray-800 dark:text-white mb-2">
              3. Market Resolution with Atoma
            </h3>
            <p className="text-gray-700 dark:text-white leading-relaxed">
              Once a market expires, Stakcast utilizes Atoma’s agents and TEEs
              to validate the outcome. These agents collect data from trusted
              sources and securely process it within a TEE, ensuring the results
              are tamper-proof and verifiable.
            </p>
          </div>

          {/* Step 4 */}
          <div className="bg-white dark:bg-slate-950 shadow-md rounded-lg p-6">
            <h3 className="text-xl font-bold text-gray-800 dark:text-white mb-2">
              4. Rewards Distribution
            </h3>
            <p className="text-gray-700 dark:text-white leading-relaxed">
              After the market outcome is validated, rewards are distributed
              proportionally to the users based on their staked positions. The
              entire process is trustless and executed via smart contracts
              deployed on StarkNet.
            </p>
          </div>
        </div>

        {/* Why Atoma Section */}
        <div className="mt-12 bg-blue-50 dark:bg-slate-950 border-l-4 border-blue-500 p-6 rounded-lg">
          <h3 className="text-2xl font-bold text-blue-600 mb-4">
            Why Atoma and TEEs?
          </h3>
          <p className="text-gray-700 dark:text-white leading-relaxed">
            Atoma provides a powerful framework for creating decentralized
            agents that utilize Trusted Execution Environments (TEEs). These
            TEEs ensure that sensitive computations, such as market outcome
            validation, are conducted securely and transparently. By integrating
            Atoma, Stakcast achieves:
          </p>
          <ul className="list-disc list-inside mt-4 text-gray-700 dark:text-white space-y-2">
            <li>
              <strong>Data Integrity:</strong> Outcomes are verified using
              trusted data sources, ensuring accuracy and reliability.
            </li>
            <li>
              <strong>Privacy:</strong> Sensitive computations are conducted in
              a secure enclave, preventing tampering or leaks.
            </li>
            <li>
              <strong>Transparency:</strong> All validation processes are
              auditable, fostering trust among users.
            </li>
          </ul>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;