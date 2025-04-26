import { BaseProps } from "@/app/types";

type GlassCardProps = BaseProps & {
  children: React.ReactNode;
  ariaLabel?: string; // Optional aria-label for accessibility
};

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  className = "",
  ariaLabel, 
}) => (
  <div
    className={`backdrop-blur-sm bg-white/30 rounded-2xl p-6 shadow-lg border border-white/20 transition-all duration-300 hover:shadow-xl ${className}`}
    aria-label={ariaLabel} // Accessibility: Apply aria-label if provided
    role="region" 
  >
    {children}
  </div>
);