'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { DataTable } from '@/components/data-table';
import { UserReport } from '@/lib/queries';
import { CheckCircle2, Trash2, Clock, Mail, Tag } from 'lucide-react';

interface ReportsClientProps {
  initialReports: UserReport[];
}

export default function ReportsClient({ initialReports }: ReportsClientProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const handleResolve = async (id: string) => {
    setLoading(true);
    try {
      const res = await fetch('/api/reports/resolve', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id }),
      });
      if (res.ok) {
        router.refresh();
      } else {
        alert('Failed to resolve report');
      }
    } catch (err) {
      alert('Error resolving report');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to dismiss this report?')) return;
    setLoading(true);
    try {
      const res = await fetch('/api/reports/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id }),
      });
      if (res.ok) {
        router.refresh();
      } else {
        alert('Failed to delete report');
      }
    } catch (err) {
      alert('Error deleting report');
    } finally {
      setLoading(false);
    }
  };

  // Client-side filtering for simplicity since reports are small mock datasets
  let filteredReports = [...initialReports];

  if (search) {
    filteredReports = filteredReports.filter(
      (r) =>
        r.user_name.toLowerCase().includes(search.toLowerCase()) ||
        r.message.toLowerCase().includes(search.toLowerCase()) ||
        r.email.toLowerCase().includes(search.toLowerCase())
    );
  }

  if (typeFilter) {
    filteredReports = filteredReports.filter((r) => r.type === typeFilter);
  }

  if (statusFilter) {
    filteredReports = filteredReports.filter((r) => r.status === statusFilter);
  }

  const columns = [
    {
      header: 'Report Info',
      accessor: (report: UserReport) => (
        <div className="space-y-1">
          <span className="font-semibold text-white block">{report.user_name}</span>
          <span className="text-zinc-500 text-xs flex items-center gap-1">
            <Mail size={12} /> {report.email}
          </span>
          <span className="text-zinc-500 text-xs flex items-center gap-1">
            <Clock size={12} /> {new Date(report.created_at).toLocaleString()}
          </span>
        </div>
      ),
    },
    {
      header: 'Category Type',
      accessor: (report: UserReport) => {
        const colors = {
          Bug: 'bg-rose-500/10 text-rose-400 border-rose-500/20',
          Feedback: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
          Billing: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
          Other: 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20',
        };
        return (
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border flex items-center gap-1.5 w-fit ${colors[report.type]}`}>
            <Tag size={10} />
            {report.type}
          </span>
        );
      },
    },
    {
      header: 'User Message',
      accessor: (report: UserReport) => (
        <p className="text-zinc-300 font-medium max-w-md whitespace-pre-line text-xs leading-relaxed">
          {report.message}
        </p>
      ),
    },
    {
      header: 'Status',
      accessor: (report: UserReport) => (
        <span
          className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${
            report.status === 'Resolved'
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
              : 'bg-amber-500/10 text-amber-400 border-amber-500/20'
          }`}
        >
          {report.status}
        </span>
      ),
    },
    {
      header: 'Actions',
      accessor: (report: UserReport) => (
        <div className="flex items-center gap-2">
          {report.status === 'Pending' && (
            <button
              onClick={() => handleResolve(report.id)}
              disabled={loading}
              className="p-1.5 rounded bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 hover:text-white hover:bg-emerald-600 transition-colors"
              title="Mark as Resolved"
            >
              <CheckCircle2 size={15} />
            </button>
          )}
          <button
            onClick={() => handleDelete(report.id)}
            disabled={loading}
            className="p-1.5 rounded bg-rose-500/10 border border-rose-500/20 text-rose-400 hover:text-white hover:bg-rose-600 transition-colors"
            title="Dismiss / Delete"
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
        value={typeFilter}
        onChange={(e) => setTypeFilter(e.target.value)}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Types</option>
        <option value="Bug">Bug Reports</option>
        <option value="Feedback">Feedback</option>
        <option value="Billing">Billing Issues</option>
        <option value="Other">Other</option>
      </select>

      <select
        value={statusFilter}
        onChange={(e) => setStatusFilter(e.target.value)}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Statuses</option>
        <option value="Pending">Pending</option>
        <option value="Resolved">Resolved</option>
      </select>
    </>
  );

  return (
    <DataTable
      data={filteredReports}
      columns={columns}
      page={1}
      totalPages={1}
      onPageChange={() => {}}
      searchQuery={search}
      onSearchChange={setSearch}
      searchPlaceholder="Search message reports..."
      filters={filters}
      loading={loading}
    />
  );
}
