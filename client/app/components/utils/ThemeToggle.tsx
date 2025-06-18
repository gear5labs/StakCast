import { useState, useEffect } from "react";
import { useTheme } from "@/app/context/ThemeContext";
import { Sun, Moon } from "lucide-react";

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  return (
    <button
      onClick={() => setTheme(theme === "light" ? "dark" : "light")}
      className="flex items-center justify-center w-7 h-7 rounded-full border border-gray-300 dark:border-gray-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark"
      aria-label="Toggle theme"
    >
      {theme === "light" ? <Sun size={20} className="text-gray-700" /> : <Moon size={20} className="text-gray-300" />}
    </button>
  );
}
