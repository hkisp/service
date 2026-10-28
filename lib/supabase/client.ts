import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Null-safe: returns null when Supabase env is missing, so the app can run
// in clearly labelled DEMO mode instead of crashing or faking auth.
let cached: SupabaseClient | null | undefined;

export function getSupabaseClient(): SupabaseClient | null {
  if (cached !== undefined) return cached;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anon) {
    cached = null;
    return null;
  }
  cached = createClient(url, anon);
  return cached;
}

export const isSupabaseConfigured = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
);
