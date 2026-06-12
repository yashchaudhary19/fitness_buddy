'use client';

import React, { useState, useEffect } from 'react';
import { Settings, Save, Sparkles, Check, AlertCircle } from 'lucide-react';

interface AppSettings {
  ai_provider: string;
  gemini_model: string;
  claude_model: string;
  gemini_api_key: string | null;
  claude_api_key: string | null;
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<AppSettings>({
    ai_provider: 'gemini',
    gemini_model: 'gemini-flash-latest',
    claude_model: 'claude-3-5-sonnet-20241022',
    gemini_api_key: '',
    claude_api_key: '',
  });

  const [initialSettings, setInitialSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Fetch settings on mount
  useEffect(() => {
    async function loadSettings() {
      try {
        const res = await fetch('/api/settings');
        const json = await res.json();
        if (json.success && json.data) {
          const data = json.data;
          setSettings({
            ai_provider: data.ai_provider || 'gemini',
            gemini_model: data.gemini_model || 'gemini-flash-latest',
            claude_model: data.claude_model || 'claude-3-5-sonnet-20241022',
            // Mask keys if they exist in the DB
            gemini_api_key: data.gemini_api_key ? '••••••••••••••••••••••••' : '',
            claude_api_key: data.claude_api_key ? '••••••••••••••••••••••••' : '',
          });
          setInitialSettings(data);
        }
      } catch (err) {
        console.error('Failed to load settings:', err);
        setMessage({ type: 'error', text: 'Failed to load system settings from server.' });
      } finally {
        setLoading(false);
      }
    }

    loadSettings();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage(null);

    // Prepare payload (do not send masked placeholder text)
    const payload: any = {
      ai_provider: settings.ai_provider,
      gemini_model: settings.gemini_model,
      claude_model: settings.claude_model,
    };

    if (settings.gemini_api_key !== '••••••••••••••••••••••••') {
      payload.gemini_api_key = settings.gemini_api_key;
    } else if (initialSettings) {
      payload.gemini_api_key = initialSettings.gemini_api_key;
    }

    if (settings.claude_api_key !== '••••••••••••••••••••••••') {
      payload.claude_api_key = settings.claude_api_key;
    } else if (initialSettings) {
      payload.claude_api_key = initialSettings.claude_api_key;
    }

    try {
      const res = await fetch('/api/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const json = await res.json();

      if (json.success) {
        setMessage({ type: 'success', text: 'AI configuration updated successfully!' });
        // Update initial settings placeholder references
        setInitialSettings({
          ai_provider: payload.ai_provider,
          gemini_model: payload.gemini_model,
          claude_model: payload.claude_model,
          gemini_api_key: payload.gemini_api_key,
          claude_api_key: payload.claude_api_key,
        });
      } else {
        setMessage({ type: 'error', text: json.error || 'Failed to update settings.' });
      }
    } catch (err: any) {
      setMessage({ type: 'error', text: err.message || 'An error occurred while saving.' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-600/10 text-blue-500">
          <Settings className="h-6 w-6" />
        </div>
        <div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight">System Settings</h1>
          <p className="text-sm text-zinc-400 mt-1">
            Toggle global AI model providers, adjust model variants, and update API keys dynamically.
          </p>
        </div>
      </div>

      {/* Main Form */}
      <form onSubmit={handleSave} className="space-y-6">
        {/* Status Messages */}
        {message && (
          <div
            className={`flex items-start gap-3 rounded-lg p-4 text-sm ${
              message.type === 'success'
                ? 'bg-emerald-500/10 border border-emerald-500/35 text-emerald-400'
                : 'bg-rose-500/10 border border-rose-500/35 text-rose-400'
            }`}
          >
            {message.type === 'success' ? (
              <Check className="h-5 w-5 shrink-0 mt-0.5" />
            ) : (
              <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />
            )}
            <div>{message.text}</div>
          </div>
        )}

        {/* 1. Global AI Provider Choice */}
        <div className="rounded-xl border border-neutral-800 bg-neutral-900/40 p-6 md:p-8">
          <h2 className="text-lg font-bold text-white flex items-center gap-2 mb-4">
            <Sparkles className="h-5 w-5 text-blue-500" />
            Active AI Provider
          </h2>
          <p className="text-xs text-zinc-500 mb-6">
            Select the primary AI brain for speech text parsing, calorie recommendations, and meal photo vision analysis.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Google Gemini Options Card */}
            <div
              onClick={() => setSettings({ ...settings, ai_provider: 'gemini' })}
              className={`cursor-pointer rounded-xl border p-5 transition-all ${
                settings.ai_provider === 'gemini'
                  ? 'border-blue-500 bg-blue-500/5 shadow-md shadow-blue-500/5'
                  : 'border-neutral-800 bg-neutral-950/40 hover:border-neutral-700'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="font-bold text-white text-base">Google Gemini</span>
                <div
                  className={`h-5 w-5 rounded-full border flex items-center justify-center ${
                    settings.ai_provider === 'gemini' ? 'border-blue-500 bg-blue-500' : 'border-neutral-700'
                  }`}
                >
                  {settings.ai_provider === 'gemini' && <Check className="h-3 w-3 text-white font-bold" />}
                </div>
              </div>
              <p className="text-xs text-zinc-400 mt-2">
                Fast and cost-efficient. Ideal for general development and routine daily logging checks.
              </p>
            </div>

            {/* Anthropic Claude Card */}
            <div
              onClick={() => setSettings({ ...settings, ai_provider: 'claude' })}
              className={`cursor-pointer rounded-xl border p-5 transition-all ${
                settings.ai_provider === 'claude'
                  ? 'border-blue-500 bg-blue-500/5 shadow-md shadow-blue-500/5'
                  : 'border-neutral-800 bg-neutral-950/40 hover:border-neutral-700'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="font-bold text-white text-base">Anthropic Claude (Paid)</span>
                <div
                  className={`h-5 w-5 rounded-full border flex items-center justify-center ${
                    settings.ai_provider === 'claude' ? 'border-blue-500 bg-blue-500' : 'border-neutral-700'
                  }`}
                >
                  {settings.ai_provider === 'claude' && <Check className="h-3 w-3 text-white font-bold" />}
                </div>
              </div>
              <p className="text-xs text-zinc-400 mt-2">
                Highest-accuracy model (Sonnet 3.5). Perfect for high-profile client demonstrations and rich outcomes.
              </p>
            </div>
          </div>
        </div>

        {/* 2. Provider Configs */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Gemini Config Card */}
          <div className="rounded-xl border border-neutral-800 bg-neutral-900/40 p-6 space-y-4">
            <h3 className="font-bold text-white text-md">Google Gemini Configs</h3>
            
            <div className="space-y-1">
              <label className="text-xs font-semibold text-zinc-400">Gemini Model Name</label>
              <select
                value={settings.gemini_model}
                onChange={(e) => setSettings({ ...settings, gemini_model: e.target.value })}
                className="w-full rounded-lg border border-neutral-800 bg-neutral-950 p-2.5 text-sm text-white focus:border-blue-500 focus:outline-none"
              >
                <option value="gemini-flash-latest">gemini-flash-latest (Recommended - 1.5/3.5)</option>
                <option value="gemini-2.5-flash">gemini-2.5-flash (Thinking variant)</option>
                <option value="gemini-2.0-flash">gemini-2.0-flash</option>
                <option value="gemini-2.5-pro">gemini-2.5-pro (High intelligence)</option>
              </select>
            </div>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-zinc-400 font-medium">Gemini API Key</label>
              <input
                type="password"
                value={settings.gemini_api_key || ''}
                placeholder="Enter Gemini API key (Leave empty to use server .env)"
                onChange={(e) => setSettings({ ...settings, gemini_api_key: e.target.value })}
                className="w-full rounded-lg border border-neutral-800 bg-neutral-950 p-2.5 text-sm text-white focus:border-blue-500 focus:outline-none placeholder-zinc-600"
              />
            </div>
          </div>

          {/* Claude Config Card */}
          <div className="rounded-xl border border-neutral-800 bg-neutral-900/40 p-6 space-y-4">
            <h3 className="font-bold text-white text-md">Anthropic Claude Configs</h3>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-zinc-400">Claude Model Name</label>
              <select
                value={settings.claude_model}
                onChange={(e) => setSettings({ ...settings, claude_model: e.target.value })}
                className="w-full rounded-lg border border-neutral-800 bg-neutral-950 p-2.5 text-sm text-white focus:border-blue-500 focus:outline-none"
              >
                <option value="claude-3-5-sonnet-20241022">claude-3-5-sonnet-latest (Default)</option>
                <option value="claude-3-5-haiku-20241022">claude-3-5-haiku-latest</option>
                <option value="claude-3-opus-20240229">claude-3-opus</option>
              </select>
            </div>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-zinc-400 font-medium">Claude API Key</label>
              <input
                type="password"
                value={settings.claude_api_key || ''}
                placeholder="Enter Claude API key (Required if Claude is active)"
                onChange={(e) => setSettings({ ...settings, claude_api_key: e.target.value })}
                className="w-full rounded-lg border border-neutral-800 bg-neutral-950 p-2.5 text-sm text-white focus:border-blue-500 focus:outline-none placeholder-zinc-600"
              />
            </div>
          </div>
        </div>

        {/* Submit Actions */}
        <div className="flex justify-end gap-4 border-t border-neutral-800 pt-6">
          <button
            type="submit"
            disabled={saving}
            className="flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-500 hover:shadow-md hover:shadow-blue-500/10 transition-colors disabled:opacity-50"
          >
            {saving ? (
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
            ) : (
              <Save className="h-4 w-4" />
            )}
            Save Configuration
          </button>
        </div>
      </form>
    </div>
  );
}
