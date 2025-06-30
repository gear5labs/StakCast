import { TrendingUp } from "lucide-react";


export const StatsCard = ({
  title,
  value,
  icon,
  trend,
  trendUp,
  description,
}: {
  title: string;
  value: string;
  icon: React.ReactNode;
  trend: string;
  trendUp: boolean;
  description: string;
}) => (
  <div className="relative overflow-hidden bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700">
    <div className="absolute inset-0 bg-gradient-to-br from-white to-slate-50 dark:from-slate-800 dark:to-slate-700" />
    <div className="relative p-6">
      <div className="flex items-center justify-between mb-4">
        <div className="p-2.5 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl text-white shadow-lg">
          {icon}
        </div>
        <div
          className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
            trendUp
              ? "bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400"
              : "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"
          }`}
        >
          <TrendingUp className="w-3 h-3" />
          {trend}
        </div>
      </div>
      <div>
        <p className="text-2xl font-bold text-slate-900 dark:text-white mb-1">
          {value}
        </p>
        <p className="text-sm font-medium text-slate-600 dark:text-slate-400">
          {title}
        </p>
        <p className="text-xs text-slate-500 dark:text-slate-500 mt-1">
          {description}
        </p>
      </div>
    </div>
  </div>
);
