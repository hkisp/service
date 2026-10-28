// In-memory usage log for the local/demo server only.
// It is intentionally NOT persisted and NOT presented as production billing.
// Real usage must come from Supabase usage_logs (see migrations) once wired.
export interface UsageEntry {
  id: string;
  modelId: string;
  providerId: string;
  status: "success" | "error" | "aborted";
  inputTokens?: number;
  outputTokens?: number;
  latencyMs: number;
  createdAt: string;
}

const entries: UsageEntry[] = [];

export function recordUsage(entry: UsageEntry) {
  entries.push(entry);
  if (entries.length > 200) entries.splice(0, entries.length - 200);
}

export function usageSummary() {
  const total = entries.length;
  const success = entries.filter((e) => e.status === "success").length;
  const failed = entries.filter((e) => e.status === "error").length;
  const inputTokens = entries.reduce((s, e) => s + (e.inputTokens ?? 0), 0);
  const outputTokens = entries.reduce((s, e) => s + (e.outputTokens ?? 0), 0);
  const byProvider: Record<string, number> = {};
  const byModel: Record<string, number> = {};
  for (const e of entries) {
    byProvider[e.providerId] = (byProvider[e.providerId] ?? 0) + 1;
    byModel[e.modelId] = (byModel[e.modelId] ?? 0) + 1;
  }
  return {
    total,
    success,
    failed,
    inputTokens,
    outputTokens,
    byProvider,
    byModel,
    recent: entries.slice(-20).reverse(),
    note: "Local in-memory demo log only. No costs are estimated here; providers do not all report prices, and no price is invented.",
  };
}
