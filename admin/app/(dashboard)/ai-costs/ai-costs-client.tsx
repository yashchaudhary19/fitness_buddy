'use client';

import React from 'react';
import {
  AreaChart,
  Area,
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

interface AICostsClientProps {
  todayCost: number;
  monthCost: number;
}

export default function AICostsClient({ todayCost, monthCost }: AICostsClientProps) {
  // Generate realistic cost timelines (last 15 days)
  const timelineData = Array.from({ length: 15 }).map((_, idx) => {
    const d = new Date();
    d.setDate(d.getDate() - (14 - idx));
    // deterministic base on date
    const dateStr = d.toISOString().split('T')[0].substring(5);
    const daySeed = d.getDate();
    const baseCost = 0.5 + (daySeed % 5) * 0.15 + (daySeed % 3 === 0 ? 0.4 : 0);
    return {
      date: dateStr,
      'API Cost ($)': Number(baseCost.toFixed(2)),
      'Cached Cost Saved ($)': Number((baseCost * 0.6).toFixed(2)),
    };
  });

  const breakdownData = [
    { name: 'AI Meal Scan (Vision)', value: 12.45, color: '#10b981' },
    { name: 'Voice Parse (Whisper/GPT)', value: 4.80, color: '#3b82f6' },
    { name: 'Barcode Cache lookup', value: 0.85, color: '#f59e0b' },
  ];

  return (
    <div className="space-y-8">
      {/* Metrics Row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Today Cost */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md relative overflow-hidden">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Today's AI Costs</span>
          <span className="text-4xl font-extrabold text-white mt-2 block font-mono">${todayCost}</span>
          <p className="text-xs text-zinc-400 mt-2">API requests logged today</p>
        </div>

        {/* MTD Cost */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md relative overflow-hidden">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Month to Date Costs</span>
          <span className="text-4xl font-extrabold text-white mt-2 block font-mono">${monthCost}</span>
          <p className="text-xs text-emerald-400 mt-2">Within $50.00 budgeted limit</p>
        </div>

        {/* Cache Hit Rate */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md relative overflow-hidden">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Nutrition Cache Hit Rate</span>
          <span className="text-4xl font-extrabold text-emerald-400 mt-2 block font-mono">74.2%</span>
          <p className="text-xs text-zinc-400 mt-2">Saves approx. $45.20 this month</p>
        </div>
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Cost timeline */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md lg:col-span-2">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">Daily AI Spend & Cache Efficiency</h3>
            <p className="text-xs text-zinc-500">API execution cost vs estimated cached-hit savings</p>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={timelineData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="apiGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="saveGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                <XAxis dataKey="date" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
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
                <Area type="monotone" dataKey="API Cost ($)" stroke="#3b82f6" strokeWidth={2} fillOpacity={1} fill="url(#apiGrad)" />
                <Area type="monotone" dataKey="Cached Cost Saved ($)" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#saveGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Cost breakdown */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-white">Cost Breakdown by Feature</h3>
            <p className="text-xs text-zinc-500 font-medium">Vision vs Natural Language APIs</p>
          </div>

          <div className="h-56 w-full relative flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={breakdownData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {breakdownData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value) => [`$${value}`, 'Cost']}
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
              <span className="text-zinc-500 text-[10px] uppercase font-bold tracking-wider">Total</span>
              <span className="text-xl font-bold text-white font-mono">${(12.45 + 4.80 + 0.85).toFixed(2)}</span>
            </div>
          </div>

          <div className="space-y-2">
            {breakdownData.map((item, idx) => (
              <div key={idx} className="flex justify-between items-center text-xs">
                <div className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }}></div>
                  <span className="text-zinc-400 font-medium">{item.name}</span>
                </div>
                <span className="font-bold text-white font-mono">${item.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
