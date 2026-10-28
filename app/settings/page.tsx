import Link from "next/link";

export default function SettingsPage() {
  return (
    <main className="min-h-screen bg-[#0a1930] text-slate-100 px-5 py-8">
      <div className="max-w-3xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">设置</h1>
          <Link href="/chat" className="px-4 py-2 rounded-xl border border-slate-700 text-sm">返回聊天</Link>
        </div>
        <section className="rounded-2xl bg-[#0f2447] border border-slate-800 p-5 space-y-3">
          <h2 className="font-bold">当前运行模式</h2>
          <p className="text-sm text-slate-400 leading-relaxed">
            未配置 Supabase 时，本站运行在 <b className="text-amber-300">演示模式</b>：访客账户为本地演示账户，
            会话只保存在浏览器 localStorage。这不是生产用户认证，也不是多用户存储。
            配置 Supabase 后，请按 README 的步骤启用 Supabase Auth 并迁移会话存储。
          </p>
        </section>
        <section className="rounded-2xl bg-[#0f2447] border border-slate-800 p-5 space-y-3">
          <h2 className="font-bold">模型默认设置</h2>
          <p className="text-sm text-slate-400 leading-relaxed">
            默认模型由服务器环境变量 <code className="bg-slate-900 px-1 rounded">IDCX_DEFAULT_MODEL</code> 决定，
            聊天页的个人选择保存在浏览器 localStorage（<code className="bg-slate-900 px-1 rounded">idcx-model-v1</code>）。
            模型启用与 API Key 配置是服务端行为，不在浏览器里改密钥。
          </p>
          <div className="flex flex-wrap gap-2">
            <Link href="/admin" className="px-4 py-2 rounded-xl bg-cyan-400 text-[#0a1930] font-bold text-sm">去模型管理</Link>
            <Link href="/chat" className="px-4 py-2 rounded-xl border border-slate-700 text-sm">去聊天页切换模型</Link>
          </div>
        </section>
        <section className="rounded-2xl bg-[#0f2447] border border-slate-800 p-5 space-y-3">
          <h2 className="font-bold">配置 .env（服务器端）</h2>
          <ol className="list-decimal ml-5 text-sm text-slate-400 space-y-2 leading-relaxed">
            <li>复制 <code className="bg-slate-900 px-1 rounded">.env.example</code> 为 <code className="bg-slate-900 px-1 rounded">.env.local</code>（不要提交到 Git）。</li>
            <li>至少填写一个服务商的 Key：OPENAI_API_KEY、ANTHROPIC_API_KEY 或 GOOGLE_GENERATIVE_AI_API_KEY。</li>
            <li>或填写 AI_GATEWAY_URL + AI_GATEWAY_API_KEY 走统一网关模式。</li>
            <li>重启开发服务器后，在聊天页上方选择“已配置”的模型。</li>
          </ol>
          <p className="text-xs text-slate-500">密钥只在服务端读取，/api/models 等接口永远不会返回完整密钥。</p>
        </section>
      </div>
    </main>
  );
}
