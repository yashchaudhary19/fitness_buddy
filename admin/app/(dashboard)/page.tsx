import React from 'react';
import { 
  getTotalUsers, 
  getNewUsersToday, 
  getDAU, 
  getMAU, 
  getAICostToday, 
  getAICostMonth,
  getSignupsChart,
  getFeatureUsageBreakdown,
  getTopLoggedFoods
} from '@/lib/queries';
import { StatCard } from '@/components/stat-card';
import OverviewCharts from './overview-charts';
import { Users, UserPlus, Activity, Eye, Cpu, DollarSign } from 'lucide-react';

export const revalidate = 0; // Disable cache to reflect database changes immediately

export default async function DashboardPage() {
  // Fetch stats in parallel
  const [
    totalUsers,
    newUsersToday,
    dau,
    mau,
    aiCostToday,
    aiCostMonth,
    signupData,
    featureData,
    topFoods,
  ] = await Promise.all([
    getTotalUsers(),
    getNewUsersToday(),
    getDAU(),
    getMAU(),
    getAICostToday(),
    getAICostMonth(),
    getSignupsChart(),
    getFeatureUsageBreakdown(),
    getTopLoggedFoods(),
  ]);

  // Calculate engagement metrics
  const activePercentage = totalUsers > 0 ? Math.round((dau / totalUsers) * 100) : 0;
  const mauPercentage = totalUsers > 0 ? Math.round((mau / totalUsers) * 100) : 0;

  return (
    <div className="space-y-8">
      {/* Welcome Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight">Overview Dashboard</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Realtime monitoring of NutriTrack application usage, database records, and AI infrastructure logs.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Users"
          value={totalUsers}
          description="Total signups in database"
          icon={Users}
          change={newUsersToday}
          changeType="positive"
        />
        <StatCard
          title="Daily Active Users"
          value={dau}
          description={`Engagement: ${activePercentage}% of total base`}
          icon={Activity}
          change={activePercentage > 0 ? activePercentage : undefined}
          changeType={activePercentage > 5 ? 'positive' : 'neutral'}
        />
        <StatCard
          title="Monthly Active Users"
          value={mau}
          description={`Retention: ${mauPercentage}% active in last 30d`}
          icon={Eye}
        />
        <StatCard
          title="AI Cost (MTD)"
          value={`$${aiCostMonth}`}
          description={`Today's cost: $${aiCostToday}`}
          icon={Cpu}
          change={12} // mock trend
          changeType="negative"
        />
      </div>

      {/* Visualizations and Lists */}
      <OverviewCharts 
        signupData={signupData} 
        featureData={featureData} 
        topFoods={topFoods} 
      />
    </div>
  );
}
