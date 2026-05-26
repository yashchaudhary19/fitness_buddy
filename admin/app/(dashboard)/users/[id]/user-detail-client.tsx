'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { UserDetails } from '@/lib/queries';
import { 
  ArrowLeft, 
  Calendar, 
  Sparkles, 
  Dumbbell, 
  Scale, 
  Flame, 
  Clock, 
  Ban, 
  CheckCircle,
  UserCheck2,
  Trash2
} from 'lucide-react';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';

interface UserDetailClientProps {
  user: UserDetails;
}

export default function UserDetailClient({ user }: UserDetailClientProps) {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<'overview' | 'food-logs'>('overview');
  const [loading, setLoading] = useState(false);

  const handleBanToggle = async () => {
    if (!confirm(`Are you sure you want to ${user.is_active ? 'ban' : 'unban'} this user?`)) return;
    setLoading(true);
    try {
      await fetch('/api/users/ban', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: user.id, isBan: user.is_active }),
      });
      router.refresh();
    } catch (err) {
      alert('Error updating user status');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm('CRITICAL WARNING: This will permanently delete this user and all logs. Irreversible! Continue?')) return;
    setLoading(true);
    try {
      await fetch('/api/users/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: user.id }),
      });
      router.push('/users');
    } catch (err) {
      alert('Error deleting user');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      {/* Back button and page controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <Link
          href="/users"
          className="inline-flex items-center gap-2 text-sm text-zinc-400 hover:text-white transition-colors"
        >
          <ArrowLeft size={16} />
          Back to Users list
        </Link>
        <div className="flex items-center gap-3">
          <button
            onClick={handleBanToggle}
            disabled={loading}
            className={`px-4 py-2 text-xs font-semibold rounded-lg border transition-all flex items-center gap-2 ${
              user.is_active
                ? 'bg-rose-500/10 border-rose-500/20 text-rose-400 hover:bg-rose-600 hover:text-white'
                : 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400 hover:bg-emerald-600 hover:text-white'
            }`}
          >
            {user.is_active ? (
              <>
                <Ban size={14} /> Ban User
              </>
            ) : (
              <>
                <UserCheck2 size={14} /> Unban User
              </>
            )}
          </button>
          <button
            onClick={handleDelete}
            disabled={loading}
            className="px-4 py-2 text-xs font-semibold rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-400 hover:bg-rose-600 hover:text-white transition-all flex items-center gap-2"
          >
            <Trash2 size={14} /> Delete User
          </button>
        </div>
      </div>

      {/* User Header Profile Card */}
      <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-xl relative overflow-hidden">
        {/* Decorative backdrop */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-emerald-500/5 via-transparent to-transparent opacity-80 pointer-events-none"></div>

        <div className="flex flex-col md:flex-row md:items-center gap-6">
          {user.avatar_url ? (
            <img
              src={user.avatar_url}
              alt={user.name}
              className="w-20 h-20 rounded-full object-cover border-2 border-emerald-500/20"
            />
          ) : (
            <div className="w-20 h-20 rounded-full bg-emerald-500/10 border-2 border-emerald-500/20 text-emerald-400 font-extrabold flex items-center justify-center text-2xl uppercase">
              {user.name.slice(0, 2)}
            </div>
          )}

          <div className="flex-1 space-y-1">
            <div className="flex items-center flex-wrap gap-3">
              <h2 className="text-2xl font-bold text-white leading-tight">{user.name}</h2>
              <span
                className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${
                  user.plan === 'Premium'
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : user.plan === 'Pro'
                    ? 'bg-blue-500/10 text-blue-400 border-blue-500/20'
                    : 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20'
                }`}
              >
                {user.plan}
              </span>
              <span
                className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${
                  user.is_active
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                    : 'bg-rose-500/10 text-rose-400 border-rose-500/20'
                }`}
              >
                {user.is_active ? 'Active' : 'Banned'}
              </span>
            </div>
            <p className="text-zinc-400 text-sm">{user.email}</p>
            <p className="text-zinc-500 text-xs flex items-center gap-1.5 mt-1">
              <Calendar size={13} />
              Joined on {new Date(user.created_at).toLocaleDateString()}
            </p>
          </div>
        </div>

        {/* Dynamic Fitness Profile Metrics */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 border-t border-[#222226] mt-6 pt-6 text-sm">
          <div>
            <span className="text-zinc-500 block text-xs">Goal Type</span>
            <span className="font-semibold text-white mt-0.5 block capitalize">{user.goal_type.replace('_', ' ')}</span>
          </div>
          <div>
            <span className="text-zinc-500 block text-xs">Age / Gender</span>
            <span className="font-semibold text-white mt-0.5 block capitalize">
              {user.age || 'N/A'} yrs / {user.gender}
            </span>
          </div>
          <div>
            <span className="text-zinc-500 block text-xs">Height</span>
            <span className="font-semibold text-white mt-0.5 block">
              {user.height_cm ? `${user.height_cm} cm` : 'N/A'}
            </span>
          </div>
          <div>
            <span className="text-zinc-500 block text-xs">Weight (Current / Target)</span>
            <span className="font-semibold text-white mt-0.5 block">
              {user.current_weight_kg ? `${user.current_weight_kg} kg` : 'N/A'} /{' '}
              {user.target_weight_kg ? `${user.target_weight_kg} kg` : 'N/A'}
            </span>
          </div>
          <div>
            <span className="text-zinc-500 block text-xs">Calorie Target</span>
            <span className="font-semibold text-emerald-400 mt-0.5 block font-mono">
              {user.daily_calorie_target} kcal
            </span>
          </div>
          <div>
            <span className="text-zinc-500 block text-xs">Activity Level</span>
            <span className="font-semibold text-white mt-0.5 block capitalize">
              {user.activity_level.replace('_', ' ')}
            </span>
          </div>
        </div>
      </div>

      {/* Tabs Menu */}
      <div className="border-b border-[#222226] flex gap-6">
        <button
          onClick={() => setActiveTab('overview')}
          className={`pb-4 text-sm font-semibold border-b-2 transition-colors ${
            activeTab === 'overview'
              ? 'border-emerald-500 text-white'
              : 'border-transparent text-zinc-500 hover:text-zinc-300'
          }`}
        >
          Activity Overview
        </button>
        <button
          onClick={() => setActiveTab('food-logs')}
          className={`pb-4 text-sm font-semibold border-b-2 transition-colors ${
            activeTab === 'food-logs'
              ? 'border-emerald-500 text-white'
              : 'border-transparent text-zinc-500 hover:text-zinc-300'
          }`}
        >
          Logged Food History ({user.food_logs.length})
        </button>
      </div>

      {/* Tab Contents */}
      {activeTab === 'overview' ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Calorie history chart */}
          <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
            <div className="mb-4">
              <h3 className="text-base font-bold text-white">Calorie Consumption (Last 30 Days)</h3>
              <p className="text-xs text-zinc-500">Daily calorie logs vs user target threshold</p>
            </div>
            <div className="h-64 w-full">
              {user.calorie_history.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={user.calorie_history} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="calorieGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                    <XAxis dataKey="date" stroke="#71717a" fontSize={10} tickLine={false} axisLine={false} />
                    <YAxis stroke="#71717a" fontSize={10} tickLine={false} axisLine={false} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1c1c21',
                        border: '1px solid #2c2c35',
                        borderRadius: '8px',
                        color: '#fff',
                      }}
                      labelStyle={{ color: '#a1a1aa', fontWeight: 'bold' }}
                    />
                    <ReferenceLine y={user.daily_calorie_target} stroke="#ef4444" strokeDasharray="3 3" label={{ value: 'Target', position: 'top', fill: '#ef4444', fontSize: 10 }} />
                    <Area type="monotone" dataKey="calories" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#calorieGrad)" name="Calories" />
                  </AreaChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-full flex items-center justify-center text-zinc-500 text-sm">
                  No calorie logs in the last 30 days
                </div>
              )}
            </div>
          </div>

          {/* Weight entry chart */}
          <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
            <div className="mb-4">
              <h3 className="text-base font-bold text-white">Weight Tracker Timeline</h3>
              <p className="text-xs text-zinc-500">Historical scale weight check-ins</p>
            </div>
            <div className="h-64 w-full">
              {user.weight_entries.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={user.weight_entries} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                    <XAxis dataKey="date" stroke="#71717a" fontSize={10} tickLine={false} axisLine={false} />
                    <YAxis stroke="#71717a" fontSize={10} tickLine={false} axisLine={false} domain={['dataMin - 5', 'dataMax + 5']} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1c1c21',
                        border: '1px solid #2c2c35',
                        borderRadius: '8px',
                        color: '#fff',
                      }}
                      labelStyle={{ color: '#a1a1aa', fontWeight: 'bold' }}
                    />
                    <Line type="monotone" dataKey="weight" stroke="#3b82f6" strokeWidth={2} activeDot={{ r: 6 }} name="Weight (kg)" />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-full flex items-center justify-center text-zinc-500 text-sm">
                  No weight entries logged by this user
                </div>
              )}
            </div>
          </div>
        </div>
      ) : (
        /* Logged food database table */
        <div className="bg-[#121214] border border-[#222226] rounded-xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#222226] bg-[#17171c]/50">
                  <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-zinc-400">Food Name</th>
                  <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-zinc-400">Meal Type</th>
                  <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-zinc-400">Calories</th>
                  <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-zinc-400">Logged Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#222226]/50">
                {user.food_logs.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-6 py-12 text-center text-zinc-500 text-sm">
                      No foods logged yet by this user.
                    </td>
                  </tr>
                ) : (
                  user.food_logs.map((log) => {
                    const mealColors = {
                      breakfast: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
                      lunch: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
                      dinner: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20',
                      snack: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
                    };
                    const mealType = log.meal_type.toLowerCase() as keyof typeof mealColors;

                    return (
                      <tr key={log.id} className="hover:bg-[#18181c]/50 transition-colors">
                        <td className="px-6 py-4 text-sm font-semibold text-white">{log.food_name}</td>
                        <td className="px-6 py-4 text-sm">
                          <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border capitalize ${mealColors[mealType] || 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20'}`}>
                            {log.meal_type}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm font-bold font-mono text-emerald-400">{log.calories} kcal</td>
                        <td className="px-6 py-4 text-xs font-medium text-zinc-500 flex items-center gap-1.5 mt-0.5">
                          <Clock size={13} />
                          {new Date(log.logged_at).toLocaleString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
