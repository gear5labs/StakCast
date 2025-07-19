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
    <div className="overflow-hidden rounded-3xl shadow-2xl bg-gradient-to-br from-white to-slate-50 dark:from-slate-900 dark:to-slate-800 border border-slate-200/60 dark:border-slate-700/60 backdrop-blur-md">
      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead className="bg-gradient-to-r from-slate-100 to-slate-200 dark:from-slate-800 dark:to-slate-700">
            <tr>
              {columns.map((col, i) => (
                <th
                  key={i}
                  className="px-8 py-5 text-left text-xs font-extrabold uppercase tracking-wider text-slate-700 dark:text-slate-200 border-b border-slate-300/40 dark:border-slate-600/40 first:rounded-tl-3xl last:rounded-tr-3xl"
                >
                  <div className="flex items-center space-x-1">
                    <span>{col.header}</span>
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr
                key={keyExtractor(row, i)}
                className={`group transition-all duration-300 ease-in-out hover:bg-gradient-to-r hover:from-blue-50/60 hover:to-indigo-50/60 dark:hover:from-blue-900/30 dark:hover:to-indigo-900/30 hover:shadow-xl hover:scale-[1.01] ${i % 2 === 0 ? 'bg-white dark:bg-slate-900/60' : 'bg-slate-50 dark:bg-slate-800/60'}`}
              >
                {columns.map((col, j) => (
                  <td
                    key={j}
                    className="px-8 py-5 text-sm text-slate-800 dark:text-slate-100 group-hover:text-slate-900 dark:group-hover:text-white transition-colors duration-200 first:rounded-bl-2xl last:rounded-br-2xl"
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
        <div className="px-8 py-16 text-center">
          <div className="text-slate-400 dark:text-slate-500 text-sm">
            <svg
              className="mx-auto h-14 w-14 mb-4 opacity-50"
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
