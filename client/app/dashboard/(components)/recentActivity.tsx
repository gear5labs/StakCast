import { Activity, History } from "lucide-react";
import React from "react";
import { DashboardCard } from "../(cards)/dashboardCard";
const RecentActivity = () => {
  return (
    <DashboardCard
      title="Recent Activity"
      description="Your latest transactions and updates"
      icon={<Activity className="w-5 h-5" />}
      iconBg="from-green-500 to-emerald-600"
    >
      <div className="flex flex-col items-center justify-center py-12">
        <div className="w-16 h-16 bg-gradient-to-br from-green-100 to-emerald-100 dark:from-green-900/30 dark:to-emerald-900/30 rounded-full flex items-center justify-center mb-4">
          <History className="w-8 h-8 text-green-600 dark:text-green-400" />
        </div>
        <h3 className="font-semibold text-slate-900 dark:text-white mb-2">
          No Recent Activity
        </h3>
        <p className="text-slate-500 dark:text-slate-400 text-center mb-4">
          Your recent transactions will appear here
        </p>
        <button className="px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-lg transition-colors text-sm font-medium">
          View All Activity
        </button>
      </div>
    </DashboardCard>
  );
};

export default RecentActivity;
