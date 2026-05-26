import React from 'react';
import AnalyticsClient from './analytics-client';

export default function AnalyticsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Product Analytics</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Deep dive into user retention cohorts, product feature adoptions, and active database engagement rates.
        </p>
      </div>

      <AnalyticsClient />
    </div>
  );
}
