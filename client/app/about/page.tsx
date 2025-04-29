"use client";
import React from "react";
import SEO from "../../../shared/components/Seo";
import DelayedContent from "../components/layout/DelayedContent";
import seoData from "../../../shared/components/seoData.json";
const page = () => {
  const { title, description, keywords, image, url } = seoData.page;
  return (
    <>
      <SEO
        title={title}
        description={description}
        keywords={keywords}
        image={image}
        url={url}
      />

      <main className="p-6">
        <h1 className="text-3xl font-bold mb-4">About page</h1>
        <p className="mb-4">@fishon amos</p>

        <h2 className="text-2xl font-semibold mt-6 mb-2">👥 @solomon</h2>
        <ul className="list-disc list-inside">
          <li>@fishon amos – Blockchain Developer</li>
          <li>@solomon – Product Strategist</li>
        </ul>

        <h2 className="text-2xl font-semibold mt-6 mb-2">🔐 Why Trust Us?</h2>
        <p>
          StakCast is built on transparency, decentralization, and security. All
          predictions are powered by smart contracts, and users can verify
          results on-chain.
        </p>
        <DelayedContent>
          <p>This content will be displayed with a delay!</p>
        </DelayedContent>
      </main>
    </>
  );
};

export default page;
