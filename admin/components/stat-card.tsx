import React from 'react';
import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  description?: string;
  change?: number;
  changeType?: 'positive' | 'negative' | 'neutral';
  icon?: LucideIcon;
  loading?: boolean;
}

export function StatCard({
  title,
  value,
  description,
  change,
  changeType = 'neutral',
  icon: Icon,
  loading = false,
}: StatCardProps) {
  if (loading) {
    return (
      <div className="bg-[#121214] border border-[#222226] rounded-xl p-6 animate-pulse">
        <div className="flex justify-between items-start">
          <div className="h-4 bg-[#2c2c35] rounded w-24 mb-3"></div>
          <div className="h-8 w-8 bg-[#2c2c35] rounded-lg"></div>
        </div>
        <div className="h-8 bg-[#2c2c35] rounded w-16 mb-2"></div>
        <div className="h-3 bg-[#2c2c35] rounded w-32"></div>
      </div>
    );
  }

  const changeColor =
    changeType === 'positive'
      ? 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20'
      : changeType === 'negative'
      ? 'text-rose-500 bg-rose-500/10 border-rose-500/20'
      : 'text-zinc-400 bg-zinc-400/10 border-zinc-400/20';

  return (
    <div className="group relative overflow-hidden bg-[#121214] hover:bg-[#151518] border border-[#222226] hover:border-[#3a3a44] transition-all duration-300 rounded-xl p-6 shadow-md hover:shadow-lg hover:shadow-emerald-500/5">
      {/* Decorative backdrop gradient */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-emerald-500/5 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"></div>

      <div className="flex justify-between items-start mb-4">
        <span className="text-sm font-medium text-zinc-400 group-hover:text-zinc-300 transition-colors">
          {title}
        </span>
        {Icon && (
          <div className="p-2 rounded-lg bg-[#1a1a1f] group-hover:bg-[#22222b] text-zinc-400 group-hover:text-emerald-400 transition-all duration-300 border border-[#222226] group-hover:border-[#33333e]">
            <Icon size={18} className="transition-transform group-hover:scale-110" />
          </div>
        )}
      </div>

      <div className="flex items-baseline space-x-2.5">
        <span className="text-3xl font-bold tracking-tight text-white">{value}</span>
        {change !== undefined && (
          <span className={`text-xs font-semibold px-2 py-0.5 rounded-full border ${changeColor}`}>
            {changeType === 'positive' ? '+' : ''}
            {change}%
          </span>
        )}
      </div>

      {description && (
        <p className="mt-2 text-xs text-zinc-500 group-hover:text-zinc-400 transition-colors">
          {description}
        </p>
      )}
    </div>
  );
}
