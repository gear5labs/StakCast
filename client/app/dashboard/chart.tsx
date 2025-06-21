import { Activity, TrendingUp } from "lucide-react";

import React from 'react'

export const Chart = () => {
  return (
   
      <div className="mb-8">
        <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-lg border border-slate-200 dark:border-slate-700">
          <div className="p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg">
                <Activity className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                  Performance Chart
                </h3>
                <p className="text-sm text-slate-600 dark:text-slate-400">
                  Your trading performance over time
                </p>
              </div>
            </div>
            <div className="h-64 flex items-center justify-center bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-700 dark:to-slate-600 rounded-xl border-2 border-dashed border-slate-300 dark:border-slate-500">
              <div className="text-center">
                <TrendingUp className="w-16 h-16 mx-auto mb-4 text-slate-400" />
                <p className="text-slate-600 dark:text-slate-300 font-medium text-lg">
                  Advanced Analytics Coming Soon
                </p>
                <p className="text-sm text-slate-500 dark:text-slate-400">
                  Interactive charts and performance metrics will appear here
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
     
  );
}

