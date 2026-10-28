// Server-only security helpers. Never import this file from client code
// (it only reads env / does pure checks, but keep the boundary explicit).

/** Reject private / loopback / link-local endpoints to prevent SSRF. */
export function isSafePublicHttpsUrl(raw: string): boolean {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return false;
  }
  if (url.protocol !== "https:") return false;
  const host = url.hostname.toLowerCase();
  if (host === "localhost" || host.endsWith(".local") || host === "::1") return false;
  if (/^127\./.test(host)) return false;
  if (/^10\./.test(host)) return false;
  if (/^192\.168\./.test(host)) return false;
  const m = host.match(/^172\.(\d+)\./);
  if (m && Number(m[1]) >= 16 && Number(m[1]) <= 31) return false;
  if (/^169\.254\./.test(host)) return false;
  // Hostnames that resolve to private IPs are still a risk in production;
  // this static check is a first line of defence, not a DNS-pinning guarantee.
  // Operators should place custom endpoints behind an allow-list proxy.
  return true;
}

export function validateCustomEndpoint(raw: string | undefined): string | null {
  if (!raw) return null;
  return isSafePublicHttpsUrl(raw) ? raw : null;
}

/** Mask a key for display: never return more than a short suffix. */
export function maskKey(key: string | undefined): string {
  if (!key) return "not configured";
  if (key.length <= 8) return "configured (masked)";
  return `configured ••••${key.slice(-4)}`;
}

// Simple in-memory, per-IP rate limit for the demo / local server.
// This is NOT a substitute for a production gateway / WAF limit.
const buckets = new Map<string, { count: number; resetAt: number }>();
const WINDOW_MS = 60_000;
const MAX_PER_MINUTE = 30;

export function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = buckets.get(ip);
  if (!entry || entry.resetAt <= now) {
    buckets.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (entry.count >= MAX_PER_MINUTE) return false;
  entry.count += 1;
  return true;
}

/** Rough token estimate for truncation only (4 chars ~= 1 token). Never used for billing. */
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}
