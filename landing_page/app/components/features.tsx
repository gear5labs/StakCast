import { BarChart2, Shield, Globe2, Zap, Users, Award } from "lucide-react";

export function Features() {
  const features = [
    {
      icon: <BarChart2 className="h-6 w-6" />,
      title: "Predict & Earn",
      description:
        "Stake tokens on your predictions and earn rewards when you're right. Our platform rewards accuracy and insight.",
    },
    {
      icon: <Globe2 className="h-6 w-6" />,
      title: "Decentralized",
      description:
        "Fully transparent and decentralized prediction markets powered by blockchain technology. No central authority.",
    },
    {
      icon: <Shield className="h-6 w-6" />,
      title: "Secure Staking",
      description:
        "Your STRK tokens will be securely locked in smart contracts during predictions. Advanced security protocols protect your assets.",
    },
    {
      icon: <Zap className="h-6 w-6" />,
      title: "Real-Time Markets",
      description:
        "Access live prediction markets for news, events, and outcomes. Real-time data and analytics at your fingertips.",
    },
    {
      icon: <Users className="h-6 w-6" />,
      title: "Community Driven",
      description:
        "Join a thriving community of predictors and market makers. Share insights and strategies with like-minded individuals.",
    },
    {
      icon: <Award className="h-6 w-6" />,
      title: "Rewards & Incentives",
      description:
        "Earn additional rewards through our referral program and community challenges. The more you participate, the more you earn.",
    },
  ];

  return (
    <section id="features" className="container mx-auto px-4 py-20">
      <div className="mb-16 text-center animate-on-scroll">
        <h2 className="mb-4 text-3xl font-bold md:text-4xl">
          Why Choose StakCast
        </h2>
        <p className="mx-auto max-w-2xl text-slate-600 dark:text-slate-300">
          Our platform will offer unique advantages for prediction market
          participants
        </p>
      </div>

      <div className="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
        {features.map((feature, i) => (
          <div
            key={i}
            className="group relative overflow-hidden rounded-2xl border bg-white dark:bg-slate-900 p-6 transition-all duration-300 hover:bg-slate-50 dark:hover:bg-slate-800 hover:shadow-lg hover:-translate-y-1 animate-on-scroll"
            style={{ animationDelay: `${i * 100}ms` }}
          >
            <div className="absolute -right-6 -top-6 h-24 w-24 rounded-full bg-gradient-to-br from-emerald-500/5 to-blue-500/5 blur-2xl transition-all duration-300 group-hover:bg-gradient-to-br group-hover:from-emerald-500/10 group-hover:to-blue-500/10 dark:from-emerald-500/20 dark:to-blue-500/20 dark:group-hover:from-emerald-500/30 dark:group-hover:to-blue-500/30"></div>

            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500/10 to-blue-500/10 dark:from-emerald-500/20 dark:to-blue-500/20 transition-transform duration-300 group-hover:scale-110">
              {feature.icon}
            </div>

            <h3 className="mb-2 text-xl font-semibold">{feature.title}</h3>
            <p className="text-slate-600 dark:text-slate-300">
              {feature.description}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
