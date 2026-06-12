'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { signOut, useSession } from 'next-auth/react';
import { 
  LayoutDashboard, 
  Users, 
  Apple, 
  Cpu, 
  BarChart3, 
  DollarSign, 
  AlertTriangle, 
  Settings, 
  LogOut 
} from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const { data: session } = useSession();

  const menuItems = [
    { name: 'Dashboard', href: '/', icon: LayoutDashboard },
    { name: 'Users', href: '/users', icon: Users },
    { name: 'Foods', href: '/foods', icon: Apple },
    { name: 'AI Costs', href: '/ai-costs', icon: Cpu },
    { name: 'Analytics', href: '/analytics', icon: BarChart3 },
    { name: 'Revenue', href: '/revenue', icon: DollarSign },
    { name: 'Reports', href: '/reports', icon: AlertTriangle },
    { name: 'Settings', href: '/settings', icon: Settings },
  ];

  return (
    <aside className="fixed inset-y-0 left-0 z-20 flex w-64 flex-col border-r border-neutral-800 bg-neutral-950 p-6 text-white">
      {/* Brand Logo */}
      <div className="flex items-center gap-3 px-2 py-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600 font-black text-white">
          NT
        </div>
        <div>
          <h1 className="font-bold tracking-tight text-neutral-100">NutriTrack</h1>
          <span className="text-xs text-neutral-400 font-medium uppercase tracking-wider">Admin Panel</span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 space-y-1 py-6">
        {menuItems.map((item) => {
          const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-blue-600 text-white shadow-md'
                  : 'text-neutral-400 hover:bg-neutral-900 hover:text-neutral-100'
              }`}
            >
              <Icon className="h-5 w-5 shrink-0" />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* Admin Account & Sign Out */}
      <div className="border-t border-neutral-800 pt-6">
        <div className="flex flex-col gap-3 px-2">
          <div className="truncate">
            <p className="text-sm font-semibold text-neutral-200">{session?.user?.name || 'System Admin'}</p>
            <p className="truncate text-xs text-neutral-500">{session?.user?.email || 'admin@example.com'}</p>
          </div>
          <button
            onClick={() => signOut({ callbackUrl: '/login' })}
            className="flex w-full items-center gap-3 rounded-lg border border-neutral-800 bg-neutral-900 px-3 py-2 text-sm font-semibold text-neutral-300 hover:bg-neutral-800 hover:text-white transition-colors"
          >
            <LogOut className="h-4 w-4" />
            Sign Out
          </button>
        </div>
      </div>
    </aside>
  );
}
