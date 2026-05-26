'use client';

import React from 'react';
import {
  AreaChart,
  Area,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

export default function AnalyticsClient() {
  // Retention Curve data (Day 1 to Day 30 cohort)
  const cohortData = [
    { day: 'Day 0', Retention: 100 },
    { day: 'Day 1', Retention: 74 },
    { day: 'Day 3', Retention: 58 },
    { day: 'Day 7', Retention: 49 },
    { day: 'Day 14', Retention: 42 },
    { day: 'Day 21', Retention: 38 },
    { day: 'Day 30', Retention: 35 },
  ];

  // Feature Adoption Rates
  const adoptionData = [
    { feature: 'Food Log', rate: 94 },
    { feature: 'Water Tracker', rate: 78 },
    { feature: 'AI Vision Scan', rate: 64 },
    { feature: 'Weight Scale', rate: 45 },
    { feature: 'Voice Parse', rate: 28 },
  ];

  // Daily engagement metrics (average logs logged per active user)
  const engagementData = Array.from({ length: 7 }).map((_, idx) => {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return {
      day: days[idx],
      'Avg Food Logs': 2.8 + (idx % 3) * 0.4 - (idx === 6 ? 0.6 : 0), // lower on Sunday
      'Avg Water Logs': 3.1 + (idx % 2) * 0.3,
    };
  });

  return (
    <div className="space-y-8">
      {/* Overview key metrics cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Average Session Duration</span>
          <span className="text-3xl font-extrabold text-white mt-1 block">4m 32s</span>
          <p className="text-xs text-emerald-400 mt-2">+12s compared to last week</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Day 7 User Retention</span>
          <span className="text-3xl font-extrabold text-white mt-1 block">49.0%</span>
          <p className="text-xs text-emerald-400 mt-2">Above health benchmark (40%)</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Weekly Log Completion</span>
          <span className="text-3xl font-extrabold text-white mt-1 block">82.3%</span>
          <p className="text-xs text-zinc-500 mt-2">Users hitting daily logs targets</p>
        </div>

        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <span className="text-zinc-500 text-xs font-semibold uppercase tracking-wider block">Scan Success Rate</span>
          <span className="text-3xl font-extrabold text-emerald-400 mt-1 block">98.4%</span>
          <p className="text-xs text-zinc-400 mt-2">AI OCR parser success rate</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Retention Curve Chart */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">User Retention Curve (30-Day Cohort)</h3>
            <p className="text-xs text-zinc-500 font-medium">Percentage of users returning after signup day</p>
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={cohortData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="retGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                <XAxis dataKey="day" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} unit="%" />
                <Tooltip
                  formatter={(value) => [`${value}%`, 'Retention']}
                  contentStyle={{
                    backgroundColor: '#1c1c21',
                    border: '1px solid #2c2c35',
                    borderRadius: '8px',
                    color: '#fff',
                  }}
                />
                <Area type="monotone" dataKey="Retention" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#retGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Feature Adoption Bar Chart */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">Feature Adoption Rates</h3>
            <p className="text-xs text-zinc-500 font-medium">Percentage of total user base utilizing feature at least once</p>
          </div>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={adoptionData} layout="vertical" margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#222226" horizontal={false} />
                <XAxis type="number" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} unit="%" />
                <YAxis type="category" dataKey="feature" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  formatter={(value) => [`${value}%`, 'Adoption']}
                  contentStyle={{
                    backgroundColor: '#1c1c21',
                    border: '1px solid #2c2c35',
                    borderRadius: '8px',
                    color: '#fff',
                  }}
                />
                <Bar dataKey="rate" fill="#3b82f6" radius={[0, 4, 4, 0]} maxBarSize={20} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Engagement logs frequency */}
        <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 shadow-md lg:col-span-2">
          <div className="mb-4">
            <h3 className="text-base font-bold text-white">Daily Logging Volume & Engagement Frequency</h3>
            <p className="text-xs text-zinc-500 font-medium">Average logs completed per active user by weekday</p>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={engagementData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#222226" vertical={false} />
                <XAxis dataKey="day" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#1c1c21',
                    border: '1px solid #2c2c35',
                    borderRadius: '8px',
                    color: '#fff',
                  }}
                />
                <Legend verticalAlign="top" height={36} iconType="circle" />
                <Line type="monotone" dataKey="Avg Food Logs" stroke="#10b981" strokeWidth={2} activeDot={{ r: 6 }} />
                <Line type="monotone" dataKey="Avg Water Logs" stroke="#3b82f6" strokeWidth={2} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
