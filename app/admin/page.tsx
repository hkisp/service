"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import type { PublicModel } from "@/lib/ai/types";

interface UsageSummary {
  total: number;
  success: number;
  failed: number;
  inputTokens: number;
  outputTokens: number;
  byProvider: Record<string, number>;
  byModel: Record<string, number>;
  recent: Array<{ id: string; modelId: string; providerId: string; status: string; latencyMs: number; createdAt: string }>;
}

export default function AdminPage() {
  const [models, setModels] = useState<PublicModel[]>([]);
  const [usage, setUsage] = useState<UsageSummary | null>(null);
  const [testResults, setTestResults] = useState<Record<string, string>>({});
  const [localToggles, setLocalToggles] = useState<Record<string, boolean>>({});
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/models").then((r) => r.json()).then((d) => {
      if (Array.isArray(d.models)) setModels(d.models);
    }).catch(() => undefined);
    fetch("/api/usage").then((r) => r.json()).then((d) => setUsage(d)).catch(() => undefined);
  }, []);

  async function toggle(modelId: string, enabled: boolean) {
    const res = await fetch("/api/models", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ modelId, enabled }),
    });
    const data = await res.json();
    setLocalToggles((prev) => ({ ...prev, [modelId]: enabled }));
    setNotice(data.message ?? "已记录（演示）");
  }

  async function test(modelId: string) {
    setTestResults((prev) => ({ ...prev, [modelId]: "测试中…" }));
    const res = await fetch("/api/models/test", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ modelId }),
    });
    const data = await res.json();
    setTestResults((prev) => ({ ...prev, [modelId]: data.lastResult ?? data.message ?? "未知" }));
  }

  return (
    <main className="min-h-screen bg-[#0a1930] text-slate-100 px-5 py-8">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">模型管理（后台）</h1>
          <Link href="/chat" className="px-4 py-2 rounded-xl border border-slate-700 text-sm">返回聊天</Link>
        </div>
        <p className="text-sm text-amber-300 bg-amber-400/10 border border-amber-400/20 rounded-xl px-4 py-3">
          注意：本页的启用/停用切换目前是演示/本地行为，不会持久化到数据库，也不会改动服务器环境变量密钥。
          生产后台必须先接 Supabase Auth + 管理员权限校验，再写 model_configs（见 README 与迁移文件注释）。
          这里永远不会显示完整 API Key，只显示“已配置 / 未配置”。
        </p>
        {notice && <p className="text-sm text-cyan-300 bg-cyan-400/10 border border-cyan-400/20 rounded-xl px-4 py-3">{notice}</p>}

        <section className="space-y-3">
          <h2 className="font-bold">服务商 / 模型</h2>
          {models.map((m) => (
            <div key={m.modelId} className="rounded-2xl bg-[#0f2447] border border-slate-800 p-4 flex flex-col sm:flex-row sm:items-center gap-3">
              <div className="flex-1 min-w-0">
                <p className="font-bold">{m.displayName}</p>
                <p className="text-xs text-slate-400 mt-1 break-words">
                  provider: {m.providerId} · providerModelId: {m.providerModelId} · 上下文 {m.contextWindow.toLocaleString()} · 最大输出 {m.maxOutputTokens}
                </p>
                <p className="text-xs mt-1">
                  状态：{m.enabled ? "已启用" : "已停用"} · {m.configured ? <span className="text-emerald-300">已配置（密钥已掩码，不显示）</span> : <span className="text-amber-300">未配置</span>}
                  {localToggles[m.modelId] !== undefined && <span className="text-slate-400"> · 本地切换：{localToggles[m.modelId] ? "启用" : "停用"}（演示）</span>}
                </p>
                {testResults[m.modelId] && <p className="text-xs text-slate-300 mt-2">{testResults[m.modelId]}</p>}
              </div>
              <div className="flex gap-2 shrink-0">
                <button onClick={() => toggle(m.modelId, !m.enabled)} className="px-3 py-2 rounded-lg border border-slate-600 text-sm">{m.enabled ? "停用（演示）" : "启用（演示）"}</button>
                <button onClick={() => test(m.modelId)} className="px-3 py-2 rounded-lg bg-cyan-400 text-[#0a1930] font-bold text-sm">测试连接</button>
              </div>
            </div>
          ))}
          {models.length === 0 && <p className="text-sm text-slate-400">正在加载模型列表…</p>}
        </section>

        <section className="rounded-2xl bg-[#0f2447] border border-slate-800 p-5">
          <h2 className="font-bold">用量统计（本地真实计数，无费用估算）</h2>
          {!usage ? (
            <p className="text-sm text-slate-400 mt-2">加载中…</p>
          ) : (
            <div className="text-sm text-slate-300 mt-3 space-y-1">
              <p>总请求：{usage.total} · 成功：{usage.success} · 失败：{usage.failed}</p>
              <p>输入 Token：{usage.inputTokens} · 输出 Token：{usage.outputTokens}（仅服务商返回时才有，否则为 0，不代表真实账单）</p>
              <p>按服务商：{Object.keys(usage.byProvider).length ? JSON.stringify(usage.byProvider) : "暂无"}</p>
              <p>按模型：{Object.keys(usage.byModel).length ? JSON.stringify(usage.byModel) : "暂无"}</p>
              <p className="text-xs text-slate-500">最近记录（本地内存，重启后清空）：{usage.recent.length} 条</p>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
