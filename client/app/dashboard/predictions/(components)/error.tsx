import React from "react";

interface ErrorPageProps {
  error: string;
}

const ErrorPage: React.FC<ErrorPageProps> = ({ error }) => {
  return (
    <main className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-900 px-4">
      <div className="max-w-md w-full text-center">
        <div className="flex justify-center mb-6">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="w-16 h-16 text-red-500 dark:text-red-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={1.5}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 9v2m0 4h.01M12 3C7.03 3 3 7.03 3 12s4.03 9 9 9-4.03-9-9-9z"
            />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-2">
          Something went wrong
        </h1>
        <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">{error}</p>

        <div className="text-xs text-gray-500 dark:text-gray-400 space-y-2">
          <p>
            Common causes include internet connection issues or temporary server
            problems.
          </p>
          <p>Please try again later or refresh the page.</p>
          <p>
            If the issue persists, please file a bug report at{" "}
            <a
              href="mailto:contact@stakcast.com"
              className="text-blue-600 dark:text-blue-400 hover:underline"
            >
              contact.stakcast.com
            </a>
          </p>
        </div>
      </div>
    </main>
  );
};

export default ErrorPage;
