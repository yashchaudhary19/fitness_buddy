'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { DataTable } from '@/components/data-table';
import { FoodRow } from '@/lib/queries';
import { Trash2, Plus, X } from 'lucide-react';

interface FoodsClientProps {
  initialFoods: FoodRow[];
  totalPages: number;
  currentPage: number;
  initialSearch: string;
  initialSource: string;
  initialStatus: string;
}

export default function FoodsClient({
  initialFoods,
  totalPages,
  currentPage,
  initialSearch,
  initialSource,
  initialStatus,
}: FoodsClientProps) {
  const router = useRouter();
  const [search, setSearch] = useState(initialSearch);
  const [source, setSource] = useState(initialSource);
  const [status, setStatus] = useState(initialStatus);
  const [loading, setLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);

  // Form states for manual insert
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [calories, setCalories] = useState('');
  const [carbs, setCarbs] = useState('');
  const [protein, setProtein] = useState('');
  const [fat, setFat] = useState('');
  const [foodSource, setFoodSource] = useState('api');

  const updateFilters = (newSearch: string, newSource: string, newStatus: string, newPage: number) => {
    const params = new URLSearchParams();
    if (newSearch) params.set('search', newSearch);
    if (newSource) params.set('source', newSource);
    if (newStatus) params.set('status', newStatus);
    if (newPage > 1) params.set('page', newPage.toString());

    router.push(`/foods?${params.toString()}`);
  };

  const handleSearchChange = (value: string) => {
    setSearch(value);
    updateFilters(value, source, status, 1);
  };

  const handleSourceChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    setSource(value);
    updateFilters(search, value, status, 1);
  };

  const handleStatusChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    setStatus(value);
    updateFilters(search, source, value, 1);
  };

  const handlePageChange = (newPage: number) => {
    updateFilters(search, source, status, newPage);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this food item? It will be removed from USDA/Curated logs.')) return;
    setLoading(true);
    try {
      await fetch('/api/foods/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id }),
      });
      router.refresh();
    } catch (err) {
      alert('Error deleting food item');
    } finally {
      setLoading(false);
    }
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !calories) {
      alert('Name and Calories per 100g are required');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/foods/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          brand,
          calories_per_100g: Number(calories),
          carbs_per_100g: Number(carbs || 0),
          protein_per_100g: Number(protein || 0),
          fat_per_100g: Number(fat || 0),
          source: foodSource,
        }),
      });

      if (res.ok) {
        setIsOpen(false);
        // Reset form
        setName('');
        setBrand('');
        setCalories('');
        setCarbs('');
        setProtein('');
        setFat('');
        setFoodSource('api');
        router.refresh();
      } else {
        const data = await res.json();
        alert(data.error || 'Failed to add food item');
      }
    } catch (err) {
      alert('Error submitting form');
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      header: 'Food Name',
      accessor: (food: FoodRow) => (
        <div>
          <span className="font-semibold text-white block">{food.name}</span>
          {food.brand && <span className="text-zinc-500 text-xs font-normal">{food.brand}</span>}
        </div>
      ),
    },
    {
      header: 'Source',
      accessor: (food: FoodRow) => {
        const colors = {
          api: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20',
          barcode: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
          custom: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
          ai_scan: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
        };
        const label = {
          api: 'USDA / API',
          barcode: 'Barcode Scan',
          custom: 'User Created',
          ai_scan: 'AI Image Scan',
        };
        return (
          <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border ${colors[food.source] || 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20'}`}>
            {label[food.source] || food.source}
          </span>
        );
      },
    },
    {
      header: 'Calories (per 100g)',
      accessor: (food: FoodRow) => (
        <span className="font-bold text-emerald-400 font-mono">{food.calories_per_100g} kcal</span>
      ),
    },
    {
      header: 'Macros (C / P / F)',
      accessor: (food: FoodRow) => (
        <span className="font-mono text-zinc-400 text-xs font-semibold">
          {food.carbs_per_100g}g / {food.protein_per_100g}g / {food.fat_per_100g}g
        </span>
      ),
    },
    {
      header: 'Creator',
      accessor: (food: FoodRow) => <span className="text-zinc-400 text-xs font-medium">{food.created_by_name}</span>,
    },
    {
      header: 'Status',
      accessor: (food: FoodRow) => {
        const colors = {
          approved: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
          pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
          flagged: 'bg-rose-500/10 text-rose-400 border-rose-500/20',
        };
        return (
          <span className={`px-2 py-0.5 rounded-full text-xs font-semibold border capitalize ${colors[food.status]}`}>
            {food.status}
          </span>
        );
      },
    },
    {
      header: 'Actions',
      accessor: (food: FoodRow) => (
        <button
          onClick={() => handleDelete(food.id)}
          disabled={loading}
          className="p-1.5 rounded bg-rose-500/10 border border-rose-500/20 text-rose-400 hover:text-white hover:bg-rose-600 transition-colors"
          title="Delete Food Item"
        >
          <Trash2 size={15} />
        </button>
      ),
    },
  ];

  const filters = (
    <>
      <select
        value={source}
        onChange={handleSourceChange}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Sources</option>
        <option value="api">USDA / API</option>
        <option value="barcode">Barcode Scanner</option>
        <option value="custom">User Custom</option>
        <option value="ai_scan">AI Meal Scan</option>
      </select>

      <select
        value={status}
        onChange={handleStatusChange}
        className="bg-[#1c1c21] border border-[#2c2c35] text-zinc-300 text-sm rounded-lg px-3 py-2 outline-none focus:border-emerald-500/50"
      >
        <option value="">All Statuses</option>
        <option value="approved">Approved</option>
        <option value="pending">Pending</option>
        <option value="flagged">Flagged</option>
      </select>

      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 border border-emerald-500/30 text-white text-sm font-semibold rounded-lg transition-all"
      >
        <Plus size={16} /> Add Food
      </button>
    </>
  );

  return (
    <div className="relative">
      <DataTable
        data={initialFoods}
        columns={columns}
        page={currentPage}
        totalPages={totalPages}
        onPageChange={handlePageChange}
        searchQuery={search}
        onSearchChange={handleSearchChange}
        searchPlaceholder="Search food items by name..."
        filters={filters}
        loading={loading}
      />

      {/* Modal Dialog for manually adding food */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-[#121214] border border-[#222226] rounded-xl w-full max-w-lg shadow-2xl overflow-hidden relative animate-in fade-in zoom-in duration-200">
            {/* Modal header */}
            <div className="px-6 py-4 border-b border-[#222226] flex items-center justify-between bg-[#151518]">
              <h3 className="font-bold text-white text-lg">Add New Food Item</h3>
              <button
                onClick={() => setIsOpen(false)}
                className="text-zinc-500 hover:text-white transition-colors"
              >
                <X size={20} />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleFormSubmit} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Food Name
                  </label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. Grilled Chicken Salad"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Brand (Optional)
                  </label>
                  <input
                    type="text"
                    value={brand}
                    onChange={(e) => setBrand(e.target.value)}
                    placeholder="e.g. Tyson Foods"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Source
                  </label>
                  <select
                    value={foodSource}
                    onChange={(e) => setFoodSource(e.target.value)}
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white outline-none transition-colors"
                  >
                    <option value="api">USDA / API</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Calories (per 100g)
                  </label>
                  <input
                    type="number"
                    required
                    value={calories}
                    onChange={(e) => setCalories(e.target.value)}
                    placeholder="120"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Carbs (per 100g)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={carbs}
                    onChange={(e) => setCarbs(e.target.value)}
                    placeholder="12.5"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Protein (per 100g)
                    </label>
                  <input
                    type="number"
                    step="0.1"
                    value={protein}
                    onChange={(e) => setProtein(e.target.value)}
                    placeholder="25.0"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-1.5">
                    Fat (per 100g)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    value={fat}
                    onChange={(e) => setFat(e.target.value)}
                    placeholder="3.2"
                    className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-lg px-3 py-2 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Form buttons */}
              <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#222226] mt-6">
                <button
                  type="button"
                  onClick={() => setIsOpen(false)}
                  className="px-4 py-2 border border-[#2c2c35] hover:bg-[#1c1c21] text-zinc-400 hover:text-white text-sm font-semibold rounded-lg transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-semibold rounded-lg hover:shadow-lg hover:shadow-emerald-500/10 transition-all"
                >
                  Save Food
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
