import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Server-only helper. Service-role key must NEVER be exposed to the browser.
// This file is not imported by any client component.
export function getSupabaseServiceClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const service = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !service) return null;
  return createClient(url, service, { auth: { persistSession: false } });
}
