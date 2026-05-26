import React from 'react';
import { getUsersTable } from '@/lib/queries';
import UsersClient from './users-client';

export const revalidate = 0;

interface UsersPageProps {
  searchParams: {
    page?: string;
    search?: string;
    plan?: string;
    status?: string;
  };
}

export default async function UsersPage({ searchParams }: UsersPageProps) {
  const currentPage = Number(searchParams.page) || 1;
  const currentSearch = searchParams.search || '';
  const currentPlan = searchParams.plan || '';
  const currentStatus = searchParams.status || '';

  const { users, totalPages } = await getUsersTable(
    currentPage,
    currentSearch,
    currentPlan,
    currentStatus
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Users Database</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Search, audit plans, view user activity, and restrict accesses or ban malicious accounts.
        </p>
      </div>

      <UsersClient
        initialUsers={users}
        totalPages={totalPages}
        currentPage={currentPage}
        initialSearch={currentSearch}
        initialPlan={currentPlan}
        initialStatus={currentStatus}
      />
    </div>
  );
}
