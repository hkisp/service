"use client";

import { useCallback, useEffect, useMemo, useRef, useState} from "react";
import Link from "next/link";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import type { PublicModel} from "@/lib/ai/types";

export interface ChatMsg {
id: string;
role: "user" | "assistant" | "system";
content: string;
modelId?: string;
feedback?: "up" | "down" | null;
}

export interface Conversation {
id: string;
title: string;
modelId: string;
messages: ChatMsg[];
createdAt: string;
updatedAt: string;
}

const LS_KEY = "idcx-conversations-v1";
const LS_MODEL = "idcx-model-v1";

function uid() {
return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

function loadConversations(): Conversation[] {
try {
const raw = localStorage.getItem(LS_KEY);
if (!raw) return [];
const parsed = JSON.parse(raw) as Conversation[];
return Array.isArray(parsed)? parsed: [];
} catch {
return [];
}
}

function CodeBlock({ language, code}: { language: string; code: string}) {
const [copied, setCopied] = useState(false);
async function copy() {
try {
await navigator.clipboard.writeText(code);
setCopied(true);
setTimeout(() => setCopied(false), 1500);
} catch {
// Clipboard unavailable (e.g. non-secure context); user can select manually.
}
}
return (
<div className="my-2 rounded-lg overflow-hidden border border-slate-700 bg-[#020617]">
<div className="flex items-center justify-between px-3 py-1.5 bg-slate-900 text-xs text-slate-400">
<span>{language || "code"}</span>
<button onClick={copy} className="px-2 py-0.5 rounded bg-slate-800 hover:bg-slate-700 text-slate-200">
{copied? "已复制": "复制代码"}
</button>
</div>
<pre className="!m-0!border-0!bg-transparent"><code className="text-sm whitespace-pre">{code}</code></pre>
</div>
);
}

function MessageItem({
msg,
isLastAssistant,
onRegenerate,
onEdit,
onFeedback,
}: {
msg: ChatMsg;
isLastAssistant: boolean;
onRegenerate: () => void;
onEdit: (newContent: string) => void;
onFeedback: (f: "up" | "down") => void;
}) {
const [copied, setCopied] = useState(false);
const [editing, setEditing] = useState(false);
const [draft, setDraft] = useState(msg.content);

async function copy() {
try {
await navigator.clipboard.writeText(msg.content);
setCopied(true);
setTimeout(() => setCopied(false), 1500);
} catch { /* ignore */}
}

if (msg.role === "user") {
return (
<div className="flex justify-end">
<div className="max-w-[85%] sm:max-w-[75%]">
{editing? (
<div className="rounded-2xl bg-[#16305e] border border-cyan-500/40 p-3">
<textarea
value={draft}
onChange={(e) => setDraft(e.target.value)}
className="w-full bg-transparent outline-none resize-y min-h-[80px] text-sm"
rows={4}
/>
<div className="flex gap-2 mt-2">
<button onClick={() => { onEdit(draft); setEditing(false);}} className="px-3 py-1 rounded bg-cyan-400 text-[#0a1930] text-sm font-semibold">保存并重新发送</button>
<button onClick={() => { setDraft(msg.content); setEditing(false);}} className="px-3 py-1 rounded border border-slate-600 text-sm">取消</button>
</div>
</div>
): (
<>
<div className="rounded-2xl bg-[#16305e] px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap break-words">{msg.content}</div>
<div className="flex gap-2 justify-end mt-1 text-xs text-slate-400">
<button onClick={copy} className="hover:text-cyan-300">{copied? "已复制": "复制"}</button>
<button onClick={() => setEditing(true)} className="hover:text-cyan-300">编辑</button>
</div>
</>
)}
</div>
</div>
);
}

return (
<div className="flex gap-3">
<div className="w-8 h-8 shrink-0 rounded-lg bg-cyan-400 text-[#0a1930] font-black flex items-center justify-center text-xs">IX</div>
<div className="flex-1 min-w-0">
<div className="rounded-2xl bg-[#0f2447] border border-slate-800 px-4 py-3 markdown-body">
<ReactMarkdown
remarkPlugins={[remarkGfm]}
components={{
code(props) {
const { className, children} = props as { className?: string; children?: React.ReactNode};
const text = String(children?? "").replace(/\n$/, "");
const match = /language-(\w+)/.exec(className || "");
if (match) return <CodeBlock language={match[1]} code={text} />;
return <code className={className}>{children}</code>;
},
pre(props) {
return <>{props.children}</>;
},
}}
>
{msg.content || "…"}
</ReactMarkdown>
</div>
<div className="flex flex-wrap gap-2 mt-1 text-xs text-slate-400">
<button onClick={copy} className="hover:text-cyan-300">{copied? "已复制": "复制"}</button>
{isLastAssistant && (
<button onClick={onRegenerate} className="hover:text-cyan-300">重新生成</button>
)}
<button onClick={() => onFeedback("up")} className={msg.feedback === "up"? "text-cyan-300": "hover:text-cyan-300"} aria-label="有帮助">👍</button>
<button onClick={() => onFeedback("down")} className={msg.feedback === "down"? "text-cyan-300": "hover:text-cyan-300"} aria-label="没帮助">👎</button>
<span className="text-slate-500">{msg.feedback? "反馈已保存在本地会话中": ""}</span>
</div>
</div>
</div>
);
}

export default function ChatClient({ initialId}: { initialId?: string}) {
const [conversations, setConversations] = useState<Conversation[]>([]);
const [activeId, setActiveId] = useState<string | null>(initialId?? null);
const [models, setModels] = useState<PublicModel[]>([]);
const [modelId, setModelId] = useState<string>("openai-gpt-5-mini");
const [mockEnabled, setMockEnabled] = useState(false);
const [input, setInput] = useState("");
const [search, setSearch] = useState("");
const [sidebarOpen, setSidebarOpen] = useState(false);
const [modelPanelOpen, setModelPanelOpen] = useState(false);
const [loading, setLoading] = useState(false);
const [error, setError] = useState<string | null>(null);
const [renamingId, setRenamingId] = useState<string | null>(null);
const [renameDraft, setRenameDraft] = useState("");
const abortRef = useRef<AbortController | null>(null);
const textareaRef = useRef<HTMLTextAreaElement | null>(null);
const scrollRef = useRef<HTMLDivElement | null>(null);

useEffect(() => {
setConversations(loadConversations());
const savedModel = localStorage.getItem(LS_MODEL);
if (savedModel) setModelId(savedModel);
fetch("/api/models")
.then((r) => r.json())
.then((d) => {
if (Array.isArray(d.models)) setModels(d.models as PublicModel[]);
if (typeof d.mockEnabled === "boolean") setMockEnabled(d.mockEnabled);
if (!savedModel && typeof d.defaultModelId === "string") setModelId(d.defaultModelId);
})
.catch(() => { /* models list failure is shown via selector empty state */});
}, []);

useEffect(() => {
try {
localStorage.setItem(LS_KEY, JSON.stringify(conversations));
} catch { /* storage full / private mode */}
}, [conversations]);

useEffect(() => {
localStorage.setItem(LS_MODEL, modelId);
}, [modelId]);

useEffect(() => {
scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight});
}, [conversations, loading]);

const active = useMemo(
() => conversations.find((c) => c.id === activeId)?? null,
[conversations, activeId],
);
const currentModel = useMemo(
() => models.find((m) => m.modelId === modelId),
[models, modelId],
);

const filtered = useMemo(() => {
const q = search.trim().toLowerCase();
if (!q) return conversations;
return conversations.filter(
(c) =>
c.title.toLowerCase().includes(q) ||
c.messages.some((m) => m.content.toLowerCase().includes(q)),
);
}, [conversations, search]);

const newChat = useCallback(() => {
const conv: Conversation = {
id: uid(),
title: "新对话",
modelId,
messages: [],
createdAt: new Date().toISOString(),
updatedAt: new Date().toISOString(),
};
setConversations((prev) => [conv,...prev]);
setActiveId(conv.id);
setError(null);
setSidebarOpen(false);
}, [modelId]);

function updateConversation(id: string, fn: (c: Conversation) => Conversation) {
setConversations((prev) => prev.map((c) => (c.id === id? fn(c): c)));
}

async function sendWithMessages(convId: string, history: ChatMsg[], modelToUse: string) {
setLoading(true);
setError(null);
const controller = new AbortController();
abortRef.current = controller;
const assistantId = uid();
updateConversation(convId, (c) => ({
...c,
messages: [...c.messages, { id: assistantId, role: "assistant", content: "", modelId: modelToUse}],
updatedAt: new Date().toISOString(),
}));
try {
const res = await fetch("/api/chat", {
method: "POST",
headers: { "Content-Type": "application/json"},
body: JSON.stringify({
modelId: modelToUse,
messages: history.map((m) => ({ role: m.role, content: m.content})),
}),
signal: controller.signal,
});
if (!res.ok ||!res.body) {
let msg = `请求失败（HTTP ${res.status}）`;
let code = "";
try {
const j = await res.json();
if (typeof j.message === "string") msg = j.message;
if (typeof j.code === "string") code = j.code;
} catch { /* keep generic */}
// Remove the empty assistant placeholder; show the error banner instead.
updateConversation(convId, (c) => ({...c, messages: c.messages.filter((m) => m.id!== assistantId)}));
setError(code? `${code}：${msg}`: msg);
return;
}
const reader = res.body.getReader();
const decoder = new TextDecoder();
let buffer = "";
let gotAny = false;
while (true) {
const { done, value} = await reader.read();
if (done) break;
buffer += decoder.decode(value, { stream: true});
const parts = buffer.split("\n\n");
buffer = parts.pop()?? "";
for (const part of parts) {
const line = part.trim();
if (!line.startsWith("data:")) continue;
let chunk: { type: string; text?: string; code?: string; message?: string};
try {
chunk = JSON.parse(line.slice(5).trim());
} catch {
continue;
}
if (chunk.type === "delta" && chunk.text) {
gotAny = true;
const text = chunk.text;
updateConversation(convId, (c) => ({
...c,
messages: c.messages.map((m) => (m.id === assistantId? {...m, content: m.content + text}: m)),
}));
} else if (chunk.type === "error") {
updateConversation(convId, (c) => ({...c, messages: c.messages.filter((m) => m.id!== assistantId)}));
setError(chunk.code? `${chunk.code}：${chunk.message?? "模型请求失败"}`: (chunk.message?? "模型请求失败"));
} else if (chunk.type === "done") {
// Stream finished cleanly.
}
}
}
if (!gotAny) {
// If the server closed without any delta and without an error event,
// keep the (empty) assistant bubble out and surface a generic error
// only if no error was already set.
setError((prev) => prev?? "未收到模型回复，请重试。");
updateConversation(convId, (c) => ({...c, messages: c.messages.filter((m) => m.id!== assistantId)}));
}
} catch (err) {
if (controller.signal.aborted) {
// User stopped: keep partial content, do not show an error.
return;
}
updateConversation(convId, (c) => ({...c, messages: c.messages.filter((m) => m.id!== assistantId)}));
setError(err instanceof Error? `网络错误：${err.message}`: "网络错误，请检查连接后重试。");
} finally {
setLoading(false);
abortRef.current = null;
}
}

async function handleSend() {
const text = input.trim();
if (!text || loading) return;
let convId = activeId;
let conv = active;
if (!convId ||!conv) {
const created: Conversation = {
id: uid(),
title: text.slice(0, 30) || "新对话",
modelId,
messages: [],
createdAt: new Date().toISOString(),
updatedAt: new Date().toISOString(),
};
setConversations((prev) => [created,...prev]);
convId = created.id;
conv = created;
setActiveId(convId);
}
const userMsg: ChatMsg = { id: uid(), role: "user", content: text};
const history = [...(conv.messages?? []), userMsg];
updateConversation(convId, (c) => ({
...c,
title: c.messages.length === 0? text.slice(0, 30): c.title,
messages: history,
modelId,
updatedAt: new Date().toISOString(),
}));
setInput("");
if (textareaRef.current) textareaRef.current.style.height = "auto";
await sendWithMessages(convId, history, modelId);
}

function regenerate() {
if (!active || loading) return;
const msgs = active.messages;
const lastUserIdx = [...msgs].map((m) => m.role).lastIndexOf("user");
if (lastUserIdx < 0) return;
const history = msgs.slice(0, lastUserIdx + 1);
updateConversation(active.id, (c) => ({...c, messages: history}));
void sendWithMessages(active.id, history, modelId);
}

function editUserMessage(msgId: string, newContent: string) {
if (!active || loading) return;
const idx = active.messages.findIndex((m) => m.id === msgId);
if (idx < 0) return;
const edited: ChatMsg = {...active.messages[idx], content: newContent};
const history = [...active.messages.slice(0, idx), edited];
updateConversation(active.id, (c) => ({...c, messages: history, title: idx === 0? newContent.slice(0, 30): c.title}));
void sendWithMessages(active.id, history, modelId);
}

function deleteConversation(id: string) {
if (!window.confirm("确定删除这个会话吗？删除后无法恢复。")) return;
setConversations((prev) => prev.filter((c) => c.id!== id));
if (activeId === id) setActiveId(null);
}

function autoGrow() {
const el = textareaRef.current;
if (!el) return;
el.style.height = "auto";
el.style.height = `${Math.min(el.scrollHeight, 200)}px`;
}

const examples = [
"用一句话介绍 IDCX AI Chat 能做什么？",
"写一段 TypeScript 代码，实现防抖函数。",
"用 Markdown 表格对比 OpenAI、Claude、Gemini 的定位。",
];

const sidebar = (
<div className="flex flex-col h-full bg-[#0d1f3d] border-r border-slate-800">
<div className="p-4 border-b border-slate-800">
<div className="flex items-center gap-2">
<div className="w-8 h-8 rounded-lg bg-cyan-400 text-[#0a1930] font-black flex items-center justify-center">IX</div>
<div>
<p className="font-bold leading-none">IDCX AI Chat</p>
<p className="text-[11px] text-slate-400 mt-1">多模型聊天</p>
</div>
</div>
<button onClick={newChat} className="w-full mt-4 py-2.5 rounded-xl bg-cyan-400 text-[#0a1930] font-bold text-sm hover:bg-cyan-300 transition">＋ 新建对话</button>
<input
value={search}
onChange={(e) => setSearch(e.target.value)}
placeholder="搜索会话…"
className="w-full mt-3 px-3 py-2 rounded-lg bg-[#0a1930] border border-slate-700 text-sm outline-none placeholder:text-slate-500 focus:border-cyan-400"
/>
</div>
<div className="flex-1 overflow-y-auto p-2 space-y-1">
{filtered.length === 0 && <p className="text-sm text-slate-500 px-3 py-4">暂无会话，点击“新建对话”开始。</p>}
{filtered.map((c) => (
<div key={c.id} className={`group rounded-lg px-3 py-2.5 cursor-pointer ${c.id === activeId? "bg-[#16305e] border border-cyan-500/30": "hover:bg-slate-800/60 border border-transparent"}`} onClick={() => { setActiveId(c.id); setModelId(c.modelId); setSidebarOpen(false);}}>
{renamingId === c.id? (
<input
autoFocus
value={renameDraft}
onChange={(e) => setRenameDraft(e.target.value)}
onBlur={() => { updateConversation(c.id, (x) => ({...x, title: renameDraft.trim() || x.title})); setRenamingId(null);}}
onKeyDown={(e) => { if (e.key === "Enter") { updateConversation(c.id, (x) => ({...x, title: renameDraft.trim() || x.title})); setRenamingId(null);}}}
onClick={(e) => e.stopPropagation()}
className="w-full bg-[#0a1930] border border-cyan-400 rounded px-2 py-1 text-sm outline-none"
/>
): (
<>
<p className="text-sm truncate font-medium">{c.title}</p>
<p className="text-[11px] text-slate-500 truncate mt-0.5">{c.messages.length} 条消息 · {c.modelId}</p>
<div className="hidden group-hover:flex gap-2 mt-1 text-[11px] text-slate-400" onClick={(e) => e.stopPropagation()}>
<button className="hover:text-cyan-300" onClick={() => { setRenamingId(c.id); setRenameDraft(c.title);}}>重命名</button>
<button className="hover:text-red-300" onClick={() => deleteConversation(c.id)}>删除</button>
</div>
</>
)}
</div>
))}
</div>
<div className="p-4 border-t border-slate-800 space-y-2 text-sm">
<Link href="/admin" className="block px-3 py-2 rounded-lg hover:bg-slate-800">⚙️ 模型管理</Link>
<Link href="/settings" className="block px-3 py-2 rounded-lg hover:bg-slate-800">🔧 设置</Link>
<div className="px-3 py-2 rounded-lg bg-slate-900/60">
<p className="text-slate-300">演示访客账户</p>
<p className="text-[11px] text-slate-500 mt-0.5">未配置 Supabase Auth 时为本地演示模式</p>
</div>
</div>
</div>
);

return (
<div className="h-screen flex bg-[#0a1930] text-slate-100 overflow-hidden">
{/* Desktop sidebar */}
<aside className="hidden md:block w-72 shrink-0 h-full">{sidebar}</aside>
{/* Mobile drawer */}
{sidebarOpen && (
<div className="fixed inset-0 z-50 md:hidden">
<div className="absolute inset-0 bg-black/60" onClick={() => setSidebarOpen(false)} />
<div className="absolute left-0 top-0 bottom-0 w-72">{sidebar}</div>
</div>
)}

<main className="flex-1 flex flex-col min-w-0">
{/* Top bar */}
<header className="flex items-center gap-2 px-3 sm:px-5 py-3 border-b border-slate-800 bg-[#0a1930]/95">
<button className="md:hidden px-2 py-1 rounded border border-slate-700" onClick={() => setSidebarOpen(true)}>☰</button>
<div className="relative">
<button onClick={() => setModelPanelOpen((v) =>!v)} className="flex items-center gap-2 px-3 py-2 rounded-xl bg-[#0f2447] border border-slate-700 text-sm font-semibold">
<span>{currentModel?.displayName?? modelId}</span>
<span className="text-xs text-slate-400">{currentModel? (currentModel.configured? "已配置": "未配置"): ""}</span>
<span>▾</span>
</button>
{modelPanelOpen && (
<div className="absolute left-0 top-12 z-40 w-80 max-w-[90vw] rounded-2xl bg-[#0f2447] border border-slate-700 shadow-2xl p-2">
{models.length === 0 && <p className="text-sm text-slate-400 px-3 py-3">正在加载模型列表…</p>}
{models.map((m) => {
const usable = m.enabled && m.configured;
return (
<button
key={m.modelId}
disabled={!usable}
onClick={() => { setModelId(m.modelId); setModelPanelOpen(false);}}
className={`w-full text-left px-3 py-2.5 rounded-xl ${m.modelId === modelId? "bg-cyan-400/15 border border-cyan-400/40": "hover:bg-slate-800"} ${!usable? "opacity-60": ""}`}
>
<span className="flex justify-between gap-2">
<span className="font-semibold text-sm">{m.displayName}</span>
<span className="text-xs">{m.modelId === modelId? "● 当前": usable? "可用": "不可用"}</span>
</span>
<span className="block text-xs text-slate-400 mt-1">
{m.providerId} · 上下文 {m.contextWindow.toLocaleString()} · {m.supportsStreaming? "流式": "非流式"}{m.supportsImages? " · 图片": ""}{m.supportsTools? " · 工具": ""}
{!m.configured? " · 未配置 API Key": ""}
{m.providerId === "mock"? " · ": ""}
</span>
</button>
);
})}
<p className="text-[11px] text-slate-500 px-3 py-2">只有“启用且已配置”的模型才能发送。未配置模型会明确报错，不会伪装回答。</p>
</div>
)}
</div>
<div className="flex-1" />
<button onClick={newChat} className="px-3 py-2 rounded-xl border border-slate-700 text-sm">＋ 新会话</button>
<Link href="/settings" className="px-3 py-2 rounded-xl border border-slate-700 text-sm hidden sm:block">设置</Link>
</header>

{mockEnabled && (
<p className="px-4 py-2 bg-amber-400/10 border-b border-amber-400/20 text-xs text-amber-300 text-center">
IDCX_MOCK_MODEL=1 已开启，Mock 模型回复仅用于测试，不是真实模型输出。
</p>
)}
<p className="px-4 py-2 bg-slate-900/50 border-b border-slate-800 text-xs text-slate-400 text-center">
演示模式：会话保存在浏览器 localStorage，仅本机可见，不是多用户生产存储。
</p>

{/* Chat area */}
<div ref={scrollRef} className="flex-1 overflow-y-auto px-4 sm:px-6 py-6">
<div className="max-w-3xl mx-auto space-y-6">
{!active || active.messages.length === 0? (
<div className="text-center py-10">
<div className="w-14 h-14 mx-auto rounded-2xl bg-cyan-400 text-[#0a1930] font-black text-xl flex items-center justify-center">IX</div>
<h1 className="text-2xl font-bold mt-4">你好，我是 IDCX AI Chat</h1>
<p className="text-slate-400 mt-2 leading-relaxed text-sm">
我可以帮你写代码、整理思路、对比方案。先在上方选择一个已配置的模型，
未配置的模型会明确提示，不会给你假回答。
</p>
<div className="grid sm:grid-cols-3 gap-3 mt-8 text-left">
{examples.map((ex) => (
<button
key={ex}
onClick={() => { setInput(ex); textareaRef.current?.focus();}}
className="rounded-2xl bg-[#0f2447] border border-slate-800 hover:border-cyan-400/50 p-4 text-sm text-left transition"
>
{ex}
</button>
))}
</div>
</div>
): (
active.messages.map((m, idx) => (
<MessageItem
key={m.id}
msg={m}
isLastAssistant={m.role === "assistant" && idx === active.messages.length - 1}
onRegenerate={regenerate}
onEdit={(content) => editUserMessage(m.id, content)}
onFeedback={(f) => updateConversation(active.id, (c) => ({...c, messages: c.messages.map((x) => (x.id === m.id? {...x, feedback: f}: x))}))}
/>
))
)}
{loading && (
<div className="flex gap-3">
<div className="w-8 h-8 rounded-lg bg-cyan-400 text-[#0a1930] font-black flex items-center justify-center text-xs">IX</div>
<div className="rounded-2xl bg-[#0f2447] border border-slate-800 px-4 py-3 text-sm text-slate-400 animate-pulse">正在生成…</div>
</div>
)}
{error && (
<div className="rounded-2xl bg-red-500/10 border border-red-500/40 px-4 py-3 text-sm text-red-200" role="alert">
<p className="font-bold">请求未完成</p>
<p className="mt-1 break-words">{error}</p>
{error.includes("MODEL_NOT_CONFIGURED") && (
<p className="mt-2 text-red-200/80">请在服务器环境变量中配置该模型的 API Key（见.env.example），或在上方切换到已配置的模型。</p>
)}
</div>
)}
</div>
</div>

{/* Composer */}
<div className="border-t border-slate-800 bg-[#0a1930] px-3 sm:px-5 py-3">
<div className="max-w-3xl mx-auto">
<div className="rounded-2xl bg-[#0f2447] border border-slate-700 focus-within:border-cyan-400 transition p-2">
<textarea
ref={textareaRef}
value={input}
onChange={(e) => { setInput(e.target.value); autoGrow();}}
onKeyDown={(e) => {
if (e.key === "Enter" &&!e.shiftKey) {
e.preventDefault();
void handleSend();
}
}}
placeholder="输入消息… Enter 发送，Shift + Enter 换行"
rows={1}
className="w-full bg-transparent outline-none resize-none px-2 py-2 text-sm leading-relaxed max-h-[200px]"
/>
<div className="flex items-center justify-between px-1 pb-1">
<span className="text-[11px] text-slate-500">
当前模型：{currentModel?.displayName?? modelId}
{currentModel &&!currentModel.configured? "（未配置，发送将报错）": ""}
</span>
<div className="flex gap-2">
{loading? (
<button onClick={() => abortRef.current?.abort()} className="px-4 py-2 rounded-xl bg-red-500 text-white text-sm font-bold">停止生成</button>
): (
<button onClick={() => void handleSend()} disabled={!input.trim()} className="px-5 py-2 rounded-xl bg-cyan-400 text-[#0a1930] text-sm font-bold disabled:opacity-40">发送</button>
)}
</div>
</div>
</div>
<p className="text-center text-[11px] text-slate-600 mt-2">AI 回答可能不准确，请核对重要信息。输入框会随内容扩展，不会遮挡聊天记录。</p>
</div>
</div>
</main>
</div>
);
}
