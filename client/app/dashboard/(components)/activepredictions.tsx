import React from "react";
import { DashboardCard } from "../(cards)/dashboardCard";
import { Target, History, PlusCircle, Loader } from "lucide-react";
import { useRouter } from "next/navigation";
import { AugmentedMarket, useUserPredictions } from "../../hooks/useBet";

const ActivePredictions = () => {
  const router = useRouter();
  const { predictions, loading } = useUserPredictions();
  const count = predictions.length;

  return (
    <DashboardCard
      title="Active Predictions"
      description="Your current market positions"
      icon={<Target className="w-5 h-5" />}
      iconBg="from-blue-500 to-purple-600"
    >
      <div className="flex flex-col items-center justify-center py-6 px-4">
        <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-purple-100 dark:from-blue-900/30 dark:to-purple-900/30 rounded-full flex items-center justify-center mb-4">
          <History className="w-8 h-8 text-blue-600 dark:text-blue-400" />
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-8">
            <Loader className="animate-spin w-6 h-6 text-blue-500 mb-2" />
            <p className="text-slate-600 dark:text-slate-300 text-sm">
              Loading predictions...
            </p>
          </div>
        ) : count === 0 ? (
          <>
            <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
              No Active Predictions
            </h3>
            <p className="text-slate-500 dark:text-slate-400 text-center mb-4">
              Start making predictions to see them{" "}
              <span
                onClick={() => router.push("/dashboard/predictions")}
                className="text-blue-500 hover:underline cursor-pointer"
              >
                here
              </span>
              .
            </p>
            <button
              className="flex items-center gap-2 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-lg transition-colors text-sm font-medium"
              onClick={() => router.push("/dashboard/predictions")}
            >
              <PlusCircle className="w-4 h-4" />
              Make Prediction
            </button>
          </>
        ) : (
          <>
            <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
              You have {count} active prediction{count > 1 && "s"}
            </h3>

            <div className="space-y-3 mb-2 max-h-[160px] w-full pr-1">
              {predictions
                .slice(-3)
                .reverse()
                .map((p: { market: AugmentedMarket }, index) => (
                  <div
                    key={index}
                    className="flex items-center gap-3 px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800/50 shadow-sm text-sm text-slate-700 dark:text-slate-300"
                  >
                    <Target className="w-4 h-4 text-blue-500 dark:text-blue-400" />
                    <span className="truncate">{p.market.title}</span>
                  </div>
                ))}
            </div>

            {count > 3 && (
              <>
                <button
                  onClick={() => router.push("/dashboard/predictions")}
                  className="text-sm text-blue-600 dark:text-blue-400 hover:underline mb-2"
                >
                  +{count - 3} more
                </button>
              </>
            )}

            {count <= 3 && (
              <button
                onClick={() => router.push("/dashboard/predictions")}
                className="flex items-center gap-2 px-4 py-2 border border-blue-500 text-blue-600 dark:text-blue-400 dark:border-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/10 rounded-lg transition-colors text-sm font-medium"
              >
                <Target className="w-4 h-4" />
                View All Predictions
              </button>
            )}
          </>
        )}
      </div>
    </DashboardCard>
  );
};

export default ActivePredictions;
