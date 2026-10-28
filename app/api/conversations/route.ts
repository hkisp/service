import { NextRequest } from "next/server";

// Demo route: conversations are stored in the browser (localStorage) in DEMO
// mode. This endpoint intentionally returns an empty, honest structure so
// the frontend never mistakes local storage for a multi-user database.
// Wiring to Supabase requires auth (see supabase/migrations/0001_init.sql).
export async function GET() {
  return Response.json({
    conversations: [],
    demoMode: true,
    note: "Demo mode: conversations live in browser localStorage only. Supabase persistence is not wired until Supabase Auth + env are configured (see README).",
  });
}

export async function POST(req: NextRequest) {
  let body: unknown = null;
  try {
    body = await req.json();
  } catch {
    // ignore; demo endpoint does not persist
  }
  return Response.json({
    ok: false,
    demoMode: true,
    message: "Not persisted on the server in demo mode. The chat UI saves conversations to localStorage.",
    received: body === null ? null : typeof body,
  });
}
