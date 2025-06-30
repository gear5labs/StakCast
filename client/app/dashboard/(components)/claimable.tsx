import React from "react";
import { useUserPredictions } from "@/app/hooks/useBet";
import { DashboardCard } from "../(cards)/dashboardCard";
import { Award } from "lucide-react";
import { formatAmount } from "@/app/utils/utils";
import { Button } from "@/components/ui/button";
import Link from "next/link";

const Claimable = () => {
  const { claimableAmount } = useUserPredictions();
  const isZero = Number(claimableAmount) === 0;

  return (
    <DashboardCard
      title="Rewards"
      icon={<Award />}
      description="Your claimable rewards from correct predictions"
    >
      <div className="p-4 rounded-xl bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/10 border border-green-200 dark:border-green-700/30">
        <div className="flex flex-col space-y-4">

          <div>
            <p className="text-sm text-green-700 dark:text-green-300 mb-3">
              {isZero
                ? "You currently have no new claimable rewards."
                : "You have rewards ready to claim!"}
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="text-center sm:text-left">
              <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
                Total Earned
              </p>
              <p className="text-lg font-semibold text-green-800 dark:text-green-200">
                {formatAmount(claimableAmount.toString() || "0")}
              </p>
            </div>

            <div className="text-center sm:text-left">
              <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
                Withdrawn
              </p>
              <p className="text-lg font-semibold text-gray-600 dark:text-gray-300">
                {formatAmount(claimableAmount.toString() || "0")}
              </p>
            </div>

            <div className="text-center sm:text-left">
              <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
                Pending
              </p>
              <p className="text-2xl font-bold text-green-800 dark:text-green-100">
                {formatAmount(claimableAmount.toString() || "0")}
              </p>
            </div>
          </div>

          {/* Action Button */}
          <div className="flex justify-center sm:justify-end pt-2">
            <Link href="/dashboard/predictions">
              <Button
                variant={isZero ? "outline" : "default"}
                className={
                  isZero
                    ? "text-green-700 border-green-600 hover:bg-green-50 dark:text-green-300 dark:border-green-400 dark:hover:bg-green-900/20"
                    : "bg-green-600 hover:bg-green-700 text-white dark:bg-green-600 dark:hover:bg-green-500"
                }
                size="sm"
              >
                {isZero ? "View Predictions" : "Claim Now"}
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </DashboardCard>
  );
};

export default Claimable;
