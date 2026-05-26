import React from 'react';
import { ChevronLeft, ChevronRight, Search } from 'lucide-react';

interface Column<T> {
  header: string;
  accessor: (item: T) => React.ReactNode;
  className?: string;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  searchQuery?: string;
  onSearchChange?: (search: string) => void;
  searchPlaceholder?: string;
  filters?: React.ReactNode;
  loading?: boolean;
}

export function DataTable<T>({
  data,
  columns,
  page,
  totalPages,
  onPageChange,
  searchQuery,
  onSearchChange,
  searchPlaceholder = 'Search...',
  filters,
  loading = false,
}: DataTableProps<T>) {
  return (
    <div className="bg-[#121214] border border-[#222226] rounded-xl overflow-hidden shadow-xl">
      {/* Table controls */}
      {(onSearchChange || filters) && (
        <div className="p-4 border-b border-[#222226] flex flex-col md:flex-row md:items-center justify-between gap-4 bg-[#151518]">
          {onSearchChange && (
            <div className="relative flex-1 max-w-md">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-zinc-500">
                <Search size={18} />
              </span>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => onSearchChange(e.target.value)}
                placeholder={searchPlaceholder}
                className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg pl-10 pr-4 py-2 text-sm text-white placeholder-zinc-500 outline-none transition-colors"
              />
            </div>
          )}
          {filters && <div className="flex flex-wrap items-center gap-3">{filters}</div>}
        </div>
      )}

      {/* Table wrapper */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-[#222226] bg-[#17171c]/50">
              {columns.map((col, idx) => (
                <th
                  key={idx}
                  className={`px-6 py-4 text-xs font-semibold uppercase tracking-wider text-zinc-400 ${
                    col.className || ''
                  }`}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-[#222226]/50">
            {loading ? (
              Array.from({ length: 5 }).map((_, rIdx) => (
                <tr key={rIdx} className="animate-pulse">
                  {columns.map((_, cIdx) => (
                    <td key={cIdx} className="px-6 py-4">
                      <div className="h-4 bg-[#202025] rounded w-full"></div>
                    </td>
                  ))}
                </tr>
              ))
            ) : data.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-6 py-12 text-center text-zinc-500">
                  No records found
                </td>
              </tr>
            ) : (
              data.map((item, rIdx) => (
                <tr
                  key={rIdx}
                  className="hover:bg-[#18181c]/50 transition-colors duration-150 group"
                >
                  {columns.map((col, cIdx) => (
                    <td
                      key={cIdx}
                      className={`px-6 py-4 text-sm text-zinc-300 font-medium ${
                        col.className || ''
                      }`}
                    >
                      {col.accessor(item)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="px-6 py-4 border-t border-[#222226] flex items-center justify-between bg-[#151518]">
          <span className="text-xs text-zinc-400">
            Page <span className="font-semibold text-white">{page}</span> of{' '}
            <span className="font-semibold text-white">{totalPages}</span>
          </span>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => onPageChange(Math.max(page - 1, 1))}
              disabled={page === 1}
              className="p-1.5 rounded bg-[#1c1c21] border border-[#2c2c35] text-zinc-400 hover:text-white hover:bg-[#25252d] disabled:opacity-50 disabled:hover:bg-[#1c1c21] disabled:hover:text-zinc-400 transition-colors"
            >
              <ChevronLeft size={16} />
            </button>
            <button
              onClick={() => onPageChange(Math.min(page + 1, totalPages))}
              disabled={page === totalPages}
              className="p-1.5 rounded bg-[#1c1c21] border border-[#2c2c35] text-zinc-400 hover:text-white hover:bg-[#25252d] disabled:opacity-50 disabled:hover:bg-[#1c1c21] disabled:hover:text-zinc-400 transition-colors"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
