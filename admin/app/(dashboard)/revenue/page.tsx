import React from 'react';
import RevenueClient from './revenue-client';

export default function RevenuePage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Revenue Metrics</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Monitor subscriptions growth, Stripe payment success rates, and customer lifetimes values.
        </p>
      </div>

      <RevenueClient />
    </div>
  );
}
