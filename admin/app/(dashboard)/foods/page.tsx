import React from 'react';
import { getFoodsTable } from '@/lib/queries';
import FoodsClient from './foods-client';

export const revalidate = 0;

interface FoodsPageProps {
  searchParams: {
    page?: string;
    search?: string;
    source?: string;
    status?: string;
  };
}

export default async function FoodsPage({ searchParams }: FoodsPageProps) {
  const currentPage = Number(searchParams.page) || 1;
  const currentSearch = searchParams.search || '';
  const currentSource = searchParams.source || '';
  const currentStatus = searchParams.status || '';

  const { foods, totalPages } = await getFoodsTable(
    currentPage,
    currentSearch,
    currentSource,
    currentStatus
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Food Database</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Monitor curated nutrition data, verify user-submitted recipes, flag incorrect logs, or add new records.
        </p>
      </div>

      <FoodsClient
        initialFoods={foods}
        totalPages={totalPages}
        currentPage={currentPage}
        initialSearch={currentSearch}
        initialSource={currentSource}
        initialStatus={currentStatus}
      />
    </div>
  );
}
