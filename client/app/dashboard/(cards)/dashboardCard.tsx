export const DashboardCard = ({
  title,
  description,
  icon,
  iconBg,
  children,
}: {
  title: string;
  description?: string;
  icon?: React.ReactNode;
  iconBg?: string;
  children: React.ReactNode;
}) => (
  <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700 h-full">
    <div className="p-6 border-b border-slate-200 dark:border-slate-700">
      <div className="flex items-center gap-3">
        {icon && (
          <div
            className={`p-2 bg-gradient-to-br ${
              iconBg || "from-slate-500 to-slate-600"
            } rounded-lg`}
          >
            <div className="text-white">{icon}</div>
          </div>
        )}
        <div>
          <h3 className="font-semibold text-slate-900 dark:text-white">
            {title}
          </h3>
          {description && (
            <p className="text-sm text-slate-600 dark:text-slate-400">
              {description}
            </p>
          )}
        </div>
      </div>
    </div>
    <div>{children}</div>
  </div>
);
