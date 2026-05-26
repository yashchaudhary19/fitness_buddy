import React from 'react';
import { getUserReports } from '@/lib/queries';
import ReportsClient from './reports-client';

export const revalidate = 0;

export default async function ReportsPage() {
  const reports = await getUserReports();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Support Tickets & Reports</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Review issues, debug log crashes reported by users, resolve billing items, or organize feedback suggestions.
        </p>
      </div>

      <ReportsClient initialReports={reports} />
    </div>
  );
}
