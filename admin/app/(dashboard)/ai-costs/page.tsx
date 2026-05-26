import React from 'react';
import { getAICostToday, getAICostMonth } from '@/lib/queries';
import AICostsClient from './ai-costs-client';

export const revalidate = 0;

export default async function AICostsPage() {
  const todayCost = await getAICostToday();
  const monthCost = await getAICostMonth();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">AI Infrastructure Costs</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Monitor API usage metrics, custom vision scan budgets, LLM prompt parsing, and caching layers performance.
        </p>
      </div>

      <AICostsClient todayCost={todayCost} monthCost={monthCost} />
    </div>
  );
}
