import React from 'react'

const SkeletonLoader = () => {
  return (
    <section className=" p-[3rem] mt-12">
      <div className="animate-pulse space-y-6">
        <div className="h-8 w-48 rounded-md bg-slate-200 dark:bg-slate-700" />

        <div className="space-y-4">
          {[...Array(3)].map((_, i) => (
            <div
              key={i}
              className="flex items-center space-x-4 p-4 rounded-xl bg-slate-100 dark:bg-slate-800"
            >
              <div className="w-10 h-10 rounded-full bg-slate-300 dark:bg-slate-700" />

              <div className="flex-1 space-y-2">
                <div className="h-4 w-3/4 rounded bg-slate-200 dark:bg-slate-600" />
                <div className="h-4 w-1/2 rounded bg-slate-200 dark:bg-slate-700" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default SkeletonLoader