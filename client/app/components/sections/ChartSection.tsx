"use client";
import { useChartData } from "@/app/hooks/useChart";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import React from "react";
import { ChartDataPoint } from "@/app/types";
interface ChartSectionProps {
  marketId: string;
}
const ChartSection: React.FC<ChartSectionProps> = ({ marketId }) => {
  const result = useChartData(marketId);

  const chartData = React.useMemo(() => {
    let yes = 0;
    let no = 0;
    if (!result.data) return [];
    return result.data.map((item: ChartDataPoint, index: number) => {
      const amt = Number(item.amount) / 1e18;
      if (item.choice === BigInt(1)) {
        yes += amt;
      } else {
        no += amt;
      }
      return {
        index,
        Yes: yes,
        No: no,
      };
    });
  }, [result]);

  return (
    <div className="mt-8 p-6 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700">
      {/* <h2 className="text-2xl font-bold text-gray-800 dark:text-white mb-6 border-b pb-4 border-gray-200 dark:border-gray-700">
        Market Trends
      </h2> */}

      {chartData.length === 0 ? (
        <div className="w-full h-80 flex items-center justify-center bg-gray-50 dark:bg-gray-900 border border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-gray-500 dark:text-gray-400 text-lg italic p-4">
          <p className="text-center">
            📊 Chart visualization will appear here soon.
            <br />
            Stay tuned for insights!
          </p>
        </div>
      ) : (
        <div className="w-full h-80">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis
                dataKey="index"
                label={{
                  value: "Vote Index",
                  position: "insideBottom",
                  offset: -5,
                }}
              />
              <YAxis
                label={{ value: "STRK", angle: -90, position: "insideLeft" }}
              />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="Yes"
                stroke="#00C49F"
                strokeWidth={2}
                dot={false}
              />
              <Line
                type="monotone"
                dataKey="No"
                stroke="#FF8042"
                strokeWidth={2}
                dot={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
};

export default ChartSection;
