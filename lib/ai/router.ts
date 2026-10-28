import type { ChatMessageInput, ModelConfig, StreamChunk} from "./types";
import { ModelError, ERROR_CODES} from "./types";
import { findModel, isProviderConfigured} from "./registry";
import { estimateTokens} from "../security";
import { streamOpenAI} from "./providers/openai";
import { streamAnthropic} from "./providers/anthropic";
import { streamGoogle} from "./providers/google";
import { streamOpenAICompatible} from "./providers/openai-compatible";
import { streamGateway} from "./providers/gateway";

/**
* Context-window truncation: keep the system message (if any) and the most
* recent turns that fit inside ~75% of the model's context window, reserving
* room for the model's output. This is a rough character-based estimate,
* not a tokenizer, and is documented as such.
*/
export function truncateMessages(
messages: ChatMessageInput[],
model: ModelConfig,
): ChatMessageInput[] {
const budget = Math.floor(model.contextWindow * 0.75);
const system = messages.filter((m) => m.role === "system");
const rest = messages.filter((m) => m.role!== "system");
const kept: ChatMessageInput[] = [];
let used = 0;
for (let i = rest.length - 1; i >= 0; i--) {
const m = rest[i];
const cost = estimateTokens(m.content) + 16;
if (used + cost > budget && kept.length > 0) break;
kept.unshift(m);
used += cost;
}
return [...system,...kept];
}

export function dedupeMessages(messages: ChatMessageInput[]): ChatMessageInput[] {
const seen = new Set<string>();
const out: ChatMessageInput[] = [];
for (const m of messages) {
const key = `${m.role}:${m.content}`;
if (seen.has(key) && m.role!== "user") {
// Never drop a user message silently in the middle; only collapse
// exact consecutive duplicates of non-user turns.
const last = out[out.length - 1];
if (last && last.role === m.role && last.content === m.content) continue;
}
seen.add(key);
out.push(m);
}
return out;
}

export function validateAndResolveModel(modelId: string): ModelConfig {
const model = findModel(modelId);
if (!model) {
throw new ModelError(ERROR_CODES.MODEL_NOT_FOUND, "Unknown model. Choose a model from the registry.", 404);
}
if (!model.enabled) {
throw new ModelError(ERROR_CODES.MODEL_DISABLED, "This model is disabled.", 403);
}
if (!isProviderConfigured(model.providerId)) {
throw new ModelError(
ERROR_CODES.MODEL_NOT_CONFIGURED,
"This model is not configured on the server. Set its API key / gateway in environment variables (see the .env.example file). No demo answer is substituted.",
503,
);
}
return model;
}

/** Async generator of unified stream chunks for one provider call. */
export async function* streamChat(
model: ModelConfig,
rawMessages: ChatMessageInput[],
signal: AbortSignal,
): AsyncGenerator<StreamChunk> {
const messages = truncateMessages(dedupeMessages(rawMessages), model);

// TEST-ONLY mock, gated by IDCX_MOCK_MODEL=1. Labelled everywhere it appears.
if (model.providerId === "mock") {
const lastUser = [...messages].reverse().find((m) => m.role === "user");
const text = `TEST-MOCK (not a real model output): 你刚才说：「${lastUser?.content ?? ""}」。对话中共有 ${messages.length} 条消息（已按顺序保留）。`;
for (const part of text.split(" ")) {
if (signal.aborted) return;
yield { type: "delta", text: part + " "};
await new Promise((r) => setTimeout(r, 10));
}
yield { type: "done", usage: null};
return;
}

let result: Awaited<ReturnType<typeof streamOpenAI>>;
switch (model.providerId) {
case "openai":
result = await streamOpenAI(model, messages, signal);
break;
case "anthropic":
result = await streamAnthropic(model, messages, signal);
break;
case "google":
result = await streamGoogle(model, messages, signal);
break;
case "openai-compatible":
result = await streamOpenAICompatible(model, messages, signal);
break;
case "gateway":
result = await streamGateway(model, messages, signal);
break;
default:
throw new ModelError(ERROR_CODES.MODEL_NOT_FOUND, "Unsupported provider.", 400);
}

try {
for await (const delta of result.textStream) {
if (signal.aborted) return;
yield { type: "delta", text: delta};
}
} catch (err) {
if (signal.aborted) return;
throw normalizeProviderError(err);
}
let usage = null;
try {
const u = await result.usage;
usage = {
inputTokens: u.inputTokens,
outputTokens: u.outputTokens,
totalTokens: u.totalTokens,
};
} catch {
usage = null;
}
yield { type: "done", usage};
}

export function normalizeProviderError(err: unknown): ModelError {
if (err instanceof ModelError) return err;
const message = err instanceof Error? err.message: "Provider request failed.";
// Never leak stack traces or keys; only a generic, safe message.
const lowered = message.toLowerCase();
if (lowered.includes("api key") || lowered.includes("unauthorized") || lowered.includes("401")) {
return new ModelError(ERROR_CODES.PROVIDER_ERROR, "Provider rejected the request (authentication). Check the server API key.", 502);
}
if (lowered.includes("429") || lowered.includes("rate limit") || lowered.includes("quota")) {
return new ModelError(ERROR_CODES.PROVIDER_ERROR, "Provider rate limit / quota reached. Try again later.", 502);
}
if (lowered.includes("aborted") || lowered.includes("abort")) {
return new ModelError(ERROR_CODES.ABORTED, "Request was cancelled.", 499);
}
return new ModelError(ERROR_CODES.PROVIDER_ERROR, "Model provider request failed. Please try again.", 502);
}

/** Serialize one SSE chunk. */
export function sse(chunk: StreamChunk): string {
return `data: ${JSON.stringify(chunk)}\n\n`;
}
