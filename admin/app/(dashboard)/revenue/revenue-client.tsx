'use client';

import React from 'react';
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';

export default function RevenueClient() {
  // Monthly revenue growth curve (Jan - May)
  const growthData = [
    { month: 'Jan', MRR: 450, 'Total Revenue': 450 },
    { month: 'Feb', MRR: 780, 'Total Revenue': 1230 },
    { month: 'Mar', MRR: 1200, 'Total Revenue': 2430 },
    { month: 'Apr', MRR: 1850, 'Total Revenue': 4280 },
    { month: 'May', MRR: 2600, 'Total Revenue': 6880 },
  ];

  // Subscription distributions
  const planData = [
    { name: 'Pro Plan ($9.99/mo)', value: 160, color: '#3b82f6' },
    { name: 'Premium Plan ($19.99/mo)', value: 50, color: '#10b981' },
    { name: 'Free Tier', value: 890, color: '#71717a' },
  ];

  // Payments transactions mock
  const recentInvoices = [
    { id: 'inv-1092', user: 'David Miller', amount: '$19.99', status: 'Succeeded', date: 'May 26, 2026' },
    { id: 'inv-1091', user: 'Sophia Watson', amount: '$9.99', status: 'Succeeded', date: 'May 25, 2026' },
    { id: 'inv-1090', user: 'James Smith', amount: '$9.99', status: 'Succeeded', date: 'May 24, 2026' },
    { id: 'inv-1089', user: 'Emma Brown', amount: '$19.99', status: 'Succeeded', date: 'May 23, 2026' },
    { id: 'inv-1088', user: 'Oliver Davis', amount: '$9.99', status: 'Failed', date: 'May 22, 2026' },
  ];

  return (
    <div className="space-y-8">
      {/* SaaS metrics row */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Monthly Recurring Revenue</span>
          <span className="text-3xl font-extrabold text-white mt-1 block font-mono">$2,599.50</span>
          <p className="text-xs text-emerald-400 mt-2">+40.5% MOM growth</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Average Revenue Per User</span>
          <span className="text-3xl font-extrabold text-white mt-1 block font-mono">$12.38</span>
          <p className="text-xs text-zinc-500 mt-2">Active paid subscribers ARPU</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Annual Run Rate (ARR)</span>
          <span className="text-3xl font-extrabold text-white mt-1 block font-mono">$31,194.00</span>
          <p className="text-xs text-zinc-400 mt-2">Estimated yearly ARR projections</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Subscriber Churn Rate</span>
          <span className="text-3xl font-extrabold text-emerald-400 mt-1 block font-mono">1.8%</span>
          <p className="text-xs text-zinc-400 mt-2">Stripe benchmark standard (2.5%)</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Revenue growth area chart */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md lg:col-span-2">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">Monthly MRR Growth & Total Billings</h3>
            <p className="text-xs text-zinc-500 font-medium">Stripe monthly recurring subscriptions volume</p>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={growthData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="mrrGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="totGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                <XAxis dataKey="month" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} unit="$" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#1c1c21',
                    border: '1px solid #2c2c35',
                    borderRadius: '8px',
                    color: '#fff',
                  }}
                  labelStyle={{ color: '#a1a1aa', fontWeight: 'bold' }}
                />
                <Legend verticalAlign="top" height={36} iconType="circle" />
                <Area type="monotone" dataKey="MRR" stroke="#3b82f6" strokeWidth={2} fillOpacity={1} fill="url(#mrrGrad)" name="MRR ($)" />
                <Area type="monotone" dataKey="Total Revenue" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#totGrad)" name="Cumulative Revenue ($)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Subscription breakdown pie */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-white">Paid Plan Distribution</h3>
            <p className="text-xs text-zinc-500 font-medium">Compare current plan allocations</p>
          </div>

          <div className="h-56 w-full relative flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={planData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {planData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value) => [`${value} users`, 'Count']}
                  contentStyle={{
                    backgroundColor: '#1c1c21',
                    border: '1px solid #2c2c35',
                    borderRadius: '8px',
                    color: '#fff',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute flex flex-col items-center justify-center">
              <span className="text-zinc-500 text-[10px] uppercase font-bold tracking-wider">Paid Users</span>
              <span className="text-xl font-bold text-white font-mono">{160 + 50}</span>
            </div>
          </div>

          <div className="space-y-2">
            {planData.map((item, idx) => (
              <div key={idx} className="flex justify-between items-center text-xs">
                <div className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }}></div>
                  <span className="text-zinc-400 font-medium">{item.name}</span>
                </div>
                <span className="font-bold text-white font-mono">{item.value} users</span>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Stripe Payments invoices */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md lg:col-span-3">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">Recent Transactions</h3>
            <p className="text-xs text-zinc-500 font-medium">Stripe billing invoice triggers</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#222226] bg-[#17171c]/50">
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-zinc-400">Invoice ID</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-zinc-400">User Customer</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-zinc-400">Amount Paid</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-zinc-400">Billing Date</th>
                  <th className="px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-zinc-400">Stripe Gateway Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#222226]/50">
                {recentInvoices.map((inv) => (
                  <tr key={inv.id} className="hover:bg-[#18181c]/50 transition-colors">
                    <td className="px-6 py-4 text-sm font-semibold text-white">{inv.id}</td>
                    <td className="px-6 py-4 text-sm text-zinc-300 font-medium">{inv.user}</td>
                    <td className="px-6 py-4 text-sm font-bold text-emerald-400 font-mono">{inv.amount}</td>
                    <td className="px-6 py-4 text-xs font-medium text-zinc-500">{inv.date}</td>
                    <td className="px-6 py-4 text-xs font-medium">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${inv.status === 'Succeeded' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border-rose-500/20'}`}>
                        {inv.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
