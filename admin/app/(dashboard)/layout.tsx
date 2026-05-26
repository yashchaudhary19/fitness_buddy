import React from 'react';
import Sidebar from '@/components/sidebar';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-[#09090b]">
      {/* Sidebar Navigation */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="pl-64">
        <main className="max-w-7xl mx-auto p-8 md:p-10">
          {children}
        </main>
      </div>
    </div>
  );
}
