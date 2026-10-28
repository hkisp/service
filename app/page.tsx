import Link from "next/link";

export default function Home() {
  return (
    <main className="min-h-screen bg-[#0a1930] text-slate-100">
      <header className="flex items-center justify-between px-5 sm:px-10 py-5 border-b border-slate-800">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-cyan-400 text-[#0a1930] font-black flex items-center justify-center">IX</div>
          <div>
            <p className="font-bold leading-none">IDCX AI Chat</p>
            <p className="text-xs text-slate-400 mt-1">多模型 AI 聊天平台</p>
          </div>
        </div>
        <nav className="flex gap-2">
          <Link href="/chat" className="px-4 py-2 rounded-lg bg-cyan-400 text-[#0a1930] font-semibold text-sm">开始聊天</Link>
          <Link href="/admin" className="px-4 py-2 rounded-lg border border-slate-700 text-sm">模型管理</Link>
          <Link href="/settings" className="px-4 py-2 rounded-lg border border-slate-700 text-sm">设置</Link>
        </nav>
      </header>
      <section className="max-w-4xl mx-auto px-5 py-14 sm:py-20 text-center">
        <p className="text-cyan-300 text-sm tracking-widest">OPENAI · CLAUDE · GEMINI · GATEWAY</p>
        <h1 className="text-4xl sm:text-5xl font-black mt-4 leading-tight">一个界面，切换多个大模型</h1>
        <p className="text-slate-400 mt-5 leading-relaxed">
          IDCX AI Chat 支持流式回答、多轮对话、历史会话和后台模型配置。
          未配置 API Key 时不会伪装成真实回答，会明确提示未配置。
        </p>
        <div className="flex flex-wrap justify-center gap-3 mt-8">
          <Link href="/chat" className="px-6 py-3 rounded-xl bg-cyan-400 text-[#0a1930] font-bold">进入聊天 →</Link>
          <Link href="/settings" className="px-6 py-3 rounded-xl border border-slate-700">查看配置说明</Link>
        </div>
        <div className="grid sm:grid-cols-3 gap-4 mt-12 text-left">
          {[
            { t: "流式 + 多轮", d: "完整历史按顺序发送给模型，支持停止生成与重新生成。" },
            { t: "模型可配置", d: "每个模型独立配置服务商、模型 ID、上下文长度与启用状态。" },
            { t: "密钥只在服务端", d: "前端永远看不到完整 API Key；自定义地址有 SSRF 安全校验。" },
          ].map((c) => (
            <div key={c.t} className="rounded-2xl bg-[#0f2447] border border-slate-800 p-5">
              <p className="font-bold">{c.t}</p>
              <p className="text-sm text-slate-400 mt-2 leading-relaxed">{c.d}</p>
            </div>
          ))}
        </div>
        <p className="text-xs text-amber-300/90 bg-amber-400/10 border border-amber-400/20 rounded-xl px-4 py-3 mt-10 inline-block">
          演示模式提示：未配置 Supabase 时，会话只保存在浏览器 localStorage，不是多用户生产存储。
        </p>
      </section>
    </main>
  );
}
