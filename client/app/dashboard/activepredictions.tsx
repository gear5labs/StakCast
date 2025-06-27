import React from "react";
import { DashboardCard } from "./dashboardCard";
import { Target, History, PlusCircle } from "lucide-react";
import { useRouter } from "next/navigation";

const ActivePredictions = () => {
  const router = useRouter();
  return (
    <DashboardCard
      title="Active Predictions"
      description="Your current market positions"
      icon={<Target className="w-5 h-5" />}
      iconBg="from-blue-500 to-purple-600"
    >
      <div className="flex flex-col items-center justify-center py-12">
        <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-purple-100 dark:from-blue-900/30 dark:to-purple-900/30 rounded-full flex items-center justify-center mb-4">
          <History className="w-8 h-8 text-blue-600 dark:text-blue-400" />
        </div>
        <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
          No Active Predictions
        </h3>
        <p className="text-slate-500 dark:text-slate-400 text-center mb-4">
          Start making predictions to see them{" "}
          <a onClick={() => router.push("/dashboard/predictions")}>here</a>
        </p>
        <button className="flex items-center gap-2 px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-lg transition-colors text-sm font-medium">
          <PlusCircle className="w-4 h-4" />
          Make Prediction
        </button>
      </div>
    </DashboardCard>
  );
};

export default ActivePredictions;
