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
} from 'recharts';

interface OverviewChartsProps {
  signupData: { date: string; Signups: number }[];
  featureData: { feature: string; count: number }[];
  topFoods: { name: string; logs: number }[];
}

export default function OverviewCharts({ signupData, featureData, topFoods }: OverviewChartsProps) {
  // Pastel/Harmonious colors for Pie Chart
  const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6', '#ec4899'];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
      {/* Signups Area Chart */}
      <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
        <div className="mb-4">
          <h3 className="text-base font-bold text-white">Daily Signups (Last 30 Days)</h3>
          <p className="text-xs text-zinc-500">Track user acquisition velocity</p>
        </div>
        <div className="h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={signupData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorSignups" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
              <XAxis
                dataKey="date"
                stroke="#71717a"
                fontSize={11}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                stroke="#71717a"
                fontSize={11}
                tickLine={false}
                axisLine={false}
                allowDecimals={false}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#1c1c21',
                  border: '1px solid #2c2c35',
                  borderRadius: '8px',
                  color: '#fff',
                }}
                labelStyle={{ color: '#a1a1aa', fontWeight: 'bold' }}
              />
              <Area
                type="monotone"
                dataKey="Signups"
                stroke="#10b981"
                strokeWidth={2}
                fillOpacity={1}
                fill="url(#colorSignups)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Feature Usage Bar Chart */}
      <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
        <div className="mb-4">
          <h3 className="text-base font-bold text-white">Feature Usage Distribution</h3>
          <p className="text-xs text-zinc-500">Compare scanner, voice, and AI meal logs</p>
        </div>
        <div className="h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={featureData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
              <XAxis
                dataKey="feature"
                stroke="#71717a"
                fontSize={11}
                tickLine={false}
                axisLine={false}
              />
              <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#1c1c21',
                  border: '1px solid #2c2c35',
                  borderRadius: '8px',
                  color: '#fff',
                }}
                cursor={{ fill: '#1c1c21', opacity: 0.3 }}
              />
              <Bar dataKey="count" name="Logs Count" fill="#3b82f6" radius={[4, 4, 0, 0]}>
                {featureData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Top Logged Foods - list layout with progress bars */}
      <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md lg:col-span-2">
        <div className="mb-6 flex justify-between items-center">
          <div>
            <h3 className="text-base font-bold text-white">Top Logged Food Items</h3>
            <p className="text-xs text-zinc-500">Most active foods consumed by users</p>
          </div>
          <span className="text-xs px-2.5 py-1 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-semibold rounded-full">
            Realtime DB
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {topFoods.map((food, idx) => {
            const maxLogs = Math.max(...topFoods.map((f) => f.logs));
            const percentage = maxLogs > 0 ? (food.logs / maxLogs) * 100 : 0;

            return (
              <div key={idx} className="flex flex-col space-y-1.5 p-3 rounded-lg hover:bg-[#1a1a1f] transition-colors duration-150">
                <div className="flex justify-between items-center text-sm">
                  <span className="font-semibold text-zinc-200">{food.name}</span>
                  <span className="font-mono text-emerald-400 font-bold">{food.logs} logs</span>
                </div>
                <div className="w-full bg-[#1c1c21] rounded-full h-2 overflow-hidden border border-[#222226]">
                  <div
                    className="bg-gradient-to-r from-emerald-500 to-teal-400 h-full rounded-full transition-all duration-500"
                    style={{ width: `${percentage}%` }}
                  ></div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
