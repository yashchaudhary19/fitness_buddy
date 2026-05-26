'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { DataTable } from '@/components/data-table';
import { UserRow, banUser, deleteUser } from '@/lib/queries';
import { ShieldAlert, Trash2, ShieldCheck, Eye } from 'lucide-react';

interface UsersClientProps {
  initialUsers: UserRow[];
  totalPages: number;
  currentPage: number;
  initialSearch: string;
  initialPlan: string;
  initialStatus: string;
}

export default function UsersClient({
  initialUsers,
  totalPages,
  currentPage,
  initialSearch,
  initialPlan,
  initialStatus,
}: UsersClientProps) {
  const router = useRouter();
  const [search, setSearch] = useState(initialSearch);
  const [plan, setPlan] = useState(initialPlan);
  const [status, setStatus] = useState(initialStatus);
  const [loading, setLoading] = useState(false);

  // Update URL search parameters
  const updateFilters = (newSearch: string, newPlan: string, newStatus: string, newPage: number) => {
    const params = new URLSearchParams();
    if (newSearch) params.set('search', newSearch);
    if (newPlan) params.set('plan', newPlan);
    if (newStatus) params.set('status', newStatus);
    if (newPage > 1) params.set('page', newPage.toString());

    router.push(`/users?${params.toString()}`);
  };

  const handleSearchChange = (value: string) => {
    setSearch(value);
    updateFilters(value, plan, status, 1);
  };

  const handlePlanChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    setPlan(value);
    updateFilters(search, value, status, 1);
  };

  const handleStatusChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    setStatus(value);
    updateFilters(search, plan, value, 1);
  };

  const handlePageChange = (newPage: number) => {
    updateFilters(search, plan, status, newPage);
  };

  const handleBanToggle = async (userId: string, currentStatus: boolean) => {
    if (!confirm(`Are you sure you want to ${currentStatus ? 'ban' : 'unban'} this user?`)) return;
    setLoading(true);
    try {
      // Direct call to query action since it runs server-side
      await fetch('/api/users/ban', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, isBan: currentStatus }),
      });
      router.refresh();
    } catch (err) {
      alert('Error updating user status');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (userId: string) => {
    if (!confirm('CRITICAL WARNING: This will permanently delete the user and all their food/weight logs from the database. This action is irreversible. Continue?')) return;
    setLoading(true);
    try {
      await fetch('/api/users/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId }),
      });
      router.refresh();
    } catch (err) {
      alert('Error deleting user');
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      header: 'Name',
      accessor: (user: UserRow) => (
        <div className="flex items-center gap-3">
          {user.avatar_url ? (
            <img
              src={user.avatar_url}
              alt={user.name}
              className="w-9 h-9 rounded-full object-cover border border-[#222226]"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-bold flex items-center justify-center text-sm uppercase">
              {user.name.slice(0, 2)}
            </div>
          )}
          <div>
            <span className="font-semibold text-white block">{user.name}</span>
            <span className="text-zinc-500 text-xs font-normal">{user.id.slice(0, 8)}...</span>
          </div>
        </div>
      ),
    },
    {
      header: 'Email',
      accessor: (user: UserRow) => <span className="text-zinc-300">{user.email}</span>,
    },
    {
      header: 'Plan',
      accessor: (user: UserRow) => {
        const colors = {
          Free: 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20',
          Pro: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
          Premium: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
        };
        return (
          <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${colors[user.plan]}`}>
            {user.plan}
          </span>
        );
      },
    },
    {
      header: 'Status',
      accessor: (user: UserRow) => (
        <span
          className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${
            user.is_active
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
              : 'bg-rose-500/10 text-rose-400 border-rose-500/20'
          }`}
        >
          {user.is_active ? 'Active' : 'Banned'}
        </span>
      ),
    },
    {
      header: 'Joined Date',
      accessor: (user: UserRow) => (
        <span className="text-zinc-400 text-xs font-medium">
          {new Date(user.created_at).toLocaleDateString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
          })}
        </span>
      ),
    },
    {
      header: 'Last Active',
      accessor: (user: UserRow) => (
        <span className="text-zinc-400 text-xs font-medium">
          {new Date(user.last_active).toLocaleDateString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
          })}
        </span>
      ),
    },
    {
      header: 'Logs',
      accessor: (user: UserRow) => (
        <span className="font-mono font-bold text-zinc-300">{user.total_logs}</span>
      ),
    },
    {
      header: 'Actions',
      accessor: (user: UserRow) => (
        <div className="flex items-center gap-2">
          <Link
            href={`/users/${user.id}`}
            className="p-1.5 rounded bg-[#1c1c21] border border-[#2c2c35] text-zinc-400 hover:text-white transition-colors"
            title="View Details"
          >
            <Eye size={15} />
          </Link>
          <button
            onClick={() => handleBanToggle(user.id, user.is_active)}
            disabled={loading}
            className={`p-1.5 rounded border transition-colors ${
              user.is_active
                ? 'bg-rose-500/10 border-rose-500/20 text-rose-400 hover:text-white hover:bg-rose-600'
                : 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400 hover:text-white hover:bg-emerald-600'
            }`}
            title={user.is_active ? 'Ban User' : 'Unban User'}
          >
            {user.is_active ? <ShieldAlert size={15} /> : <ShieldCheck size={15} />}
          </button>
          <button
            onClick={() => handleDelete(user.id)}
            disabled={loading}
            className="p-1.5 rounded bg-rose-500/10 border border-rose-500/20 text-rose-400 hover:text-white hover:bg-rose-600 transition-colors"
            title="Delete User"
          >
            <Trash2 size={15} />
          </button>
        </div>
      ),
    },
  ];

  const filters = (
    <>
      <select
        value={plan}
        onChange={handlePlanChange}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Plans</option>
        <option value="Free">Free</option>
        <option value="Pro">Pro</option>
        <option value="Premium">Premium</option>
      </select>

      <select
        value={status}
        onChange={handleStatusChange}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Statuses</option>
        <option value="active">Active</option>
        <option value="banned">Banned</option>
      </select>
    </>
  );

  return (
    <DataTable
      data={initialUsers}
      columns={columns}
      page={currentPage}
      totalPages={totalPages}
      onPageChange={handlePageChange}
      searchQuery={search}
      onSearchChange={handleSearchChange}
      searchPlaceholder="Search users by name or email..."
      filters={filters}
      loading={loading}
    />
  );
}
