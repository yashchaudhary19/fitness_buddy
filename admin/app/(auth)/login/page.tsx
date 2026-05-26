'use client';

import React, { useState, Suspense } from 'react';
import { signIn } from 'next-auth/react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Activity, Lock, Mail, AlertTriangle } from 'lucide-react';

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const callbackUrl = searchParams.get('callbackUrl') || '/';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const result = await signIn('credentials', {
        email,
        password,
        redirect: false,
        callbackUrl,
      });

      if (result?.error) {
        setError(result.error === 'CredentialsSignin' ? 'Invalid credentials' : result.error);
      } else {
        router.push(callbackUrl);
        router.refresh();
      }
    } catch {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-[#121214] border border-[#222226] shadow-2xl rounded-2xl p-8 hover:border-[#2d2d34] transition-all duration-300">
      <div className="flex flex-col items-center mb-8">
        <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 rounded-xl mb-4">
          <Activity size={28} />
        </div>
        <h1 className="text-2xl font-bold text-white tracking-tight">NutriTrack Admin</h1>
        <p className="text-zinc-400 text-sm mt-1 text-center">
          Please enter your credentials to log in to the administrator portal.
        </p>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-rose-500/10 border border-rose-500/20 rounded-xl flex items-start gap-3">
          <AlertTriangle className="text-rose-500 shrink-0 mt-0.5" size={18} />
          <p className="text-sm text-rose-400 font-medium">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5">
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-2">
            Email Address
          </label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-zinc-500">
              <Mail size={18} />
            </span>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@nutritrack.com"
              required
              className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-2">
            Password
          </label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-zinc-500">
              <Lock size={18} />
            </span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••••••"
              required
              className="w-full bg-[#1c1c21] border border-[#2c2c35] focus:border-emerald-500/50 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder-zinc-600 outline-none transition-colors"
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full mt-2 py-3 px-4 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold rounded-xl transition-all duration-300 active:scale-95 disabled:opacity-50 disabled:active:scale-100 flex items-center justify-center gap-2 border border-emerald-500/30 hover:shadow-lg hover:shadow-emerald-500/20"
        >
          {loading ? (
            <>
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              Logging in...
            </>
          ) : (
            'Sign In'
          )}
        </button>
      </form>
    </div>
  );
}

export default function LoginPage() {
  return (
    <main className="min-h-screen bg-[#09090b] flex items-center justify-center p-4 relative overflow-hidden">
      {/* Decorative background grid and gradients */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f29370a_1px,transparent_1px),linear-gradient(to_bottom,#1f29370a_1px,transparent_1px)] bg-[size:4rem_4rem]"></div>
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] rounded-full bg-emerald-500/5 blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] rounded-full bg-emerald-500/5 blur-[120px] pointer-events-none"></div>

      <div className="w-full max-w-md relative z-10">
        <Suspense fallback={
          <div className="bg-[#121214] border border-[#222226] p-8 rounded-2xl flex flex-col items-center justify-center min-h-[300px]">
            <div className="w-8 h-8 border-4 border-emerald-500/30 border-t-emerald-500 rounded-full animate-spin"></div>
            <span className="text-zinc-500 text-sm mt-4 font-semibold">Loading portal credentials...</span>
          </div>
        }>
          <LoginForm />
        </Suspense>
      </div>
    </main>
  );
}
