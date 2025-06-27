import React from "react";

interface Column<T> {
  header: string;
  accessor: (row: T) => React.ReactNode;
}

interface TableProps<T> {
  data: T[];
  columns: Column<T>[];
  keyExtractor?: (row: T, index: number) => string | number;
}

export function Table<T>({
  data,
  columns,
  keyExtractor = (_, index) => index,
}: TableProps<T>) {
  return (
    <div className="overflow-hidden rounded-2xl shadow-2xl bg-gradient-to-br from-white to-slate-50 dark:from-slate-900 dark:to-slate-800 border border-slate-200/50 dark:border-slate-700/50 backdrop-blur-sm">
      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead className="bg-gradient-to-r from-slate-100 to-slate-200 dark:from-slate-800 dark:to-slate-700">
            <tr>
              {columns.map((col, i) => (
                <th
                  key={i}
                  className="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300 border-b border-slate-300/30 dark:border-slate-600/30 first:rounded-tl-2xl last:rounded-tr-2xl"
                >
                  <div className="flex items-center space-x-1">
                    <span>{col.header}</span>
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200/40 dark:divide-slate-700/40">
            {data.map((row, i) => (
              <tr
                key={keyExtractor(row, i)}
                className="group hover:bg-gradient-to-r hover:from-blue-50/50 hover:to-indigo-50/50 dark:hover:from-blue-900/20 dark:hover:to-indigo-900/20 transition-all duration-300 ease-in-out hover:shadow-lg hover:scale-[1.001] transform"
              >
                {columns.map((col, j) => (
                  <td
                    key={j}
                    className="px-6 py-4 text-sm text-slate-700 dark:text-slate-200 group-hover:text-slate-900 dark:group-hover:text-white transition-colors duration-200"
                  >
                    <div className="flex items-center">{col.accessor(row)}</div>
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {data.length === 0 && (
        <div className="px-6 py-12 text-center">
          <div className="text-slate-400 dark:text-slate-500 text-sm">
            <svg
              className="mx-auto h-12 w-12 mb-4 opacity-50"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            No data available
          </div>
        </div>
      )}
    </div>
  );
}
