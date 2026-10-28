import { NextRequest } from "next/server";
import { z } from "zod";
import { validateAndResolveModel, streamChat, sse, normalizeProviderError } from "@/lib/ai/router";
import { ModelError, ERROR_CODES } from "@/lib/ai/types";
import { checkRateLimit } from "@/lib/security";
import { recordUsage } from "@/lib/usage";

export const runtime = "nodejs";
export const maxDuration = 60;

const messageSchema = z.object({
  role: z.enum(["system", "user", "assistant"]),
  content: z.string().min(1).max(20000),
});
const bodySchema = z.object({
  modelId: z.string().min(1).max(200),
  messages: z.array(messageSchema).min(1).max(100),
});

function clientIp(req: NextRequest): string {
  return (
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "127.0.0.1"
  );
}

export async function POST(req: NextRequest) {
  const started = Date.now();
  let modelIdForLog = "unknown";
  try {
    if (!checkRateLimit(clientIp(req))) {
      return Response.json(
        { code: ERROR_CODES.RATE_LIMITED, message: "Too many requests. Please wait a minute." },
        { status: 429 },
      );
    }
    const raw = await req.text();
    if (raw.length > 200_000) {
      return Response.json({ code: ERROR_CODES.INVALID_REQUEST, message: "Request too large." }, { status: 413 });
    }
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      return Response.json({ code: ERROR_CODES.INVALID_REQUEST, message: "Invalid JSON body." }, { status: 400 });
    }
    const body = bodySchema.safeParse(parsed);
    if (!body.success) {
      return Response.json({ code: ERROR_CODES.INVALID_REQUEST, message: "Invalid request: modelId and messages are required." }, { status: 400 });
    }
    modelIdForLog = body.data.modelId;
    const model = validateAndResolveModel(body.data.modelId);

    // 60s server timeout, combined with client disconnect signal.
    const timeout = new AbortController();
    const timer = setTimeout(() => timeout.abort(), 60_000);
    const signal = AbortSignal.any
      ? AbortSignal.any([req.signal, timeout.signal])
      : timeout.signal;

    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        let inputTokens: number | undefined;
        let outputTokens: number | undefined;
        try {
          for await (const chunk of streamChat(model, body.data.messages, signal)) {
            if (signal.aborted) break;
            if (chunk.type === "done") {
              inputTokens = chunk.usage?.inputTokens;
              outputTokens = chunk.usage?.outputTokens;
            }
            controller.enqueue(encoder.encode(sse(chunk)));
          }
          if (!signal.aborted) {
            recordUsage({
              id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              modelId: model.modelId,
              providerId: model.providerId,
              status: "success",
              inputTokens,
              outputTokens,
              latencyMs: Date.now() - started,
              createdAt: new Date().toISOString(),
            });
          } else {
            recordUsage({
              id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              modelId: model.modelId,
              providerId: model.providerId,
              status: "aborted",
              latencyMs: Date.now() - started,
              createdAt: new Date().toISOString(),
            });
          }
        } catch (err) {
          const e = normalizeProviderError(err);
          recordUsage({
            id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
            modelId: model.modelId,
            providerId: model.providerId,
            status: "error",
            latencyMs: Date.now() - started,
            createdAt: new Date().toISOString(),
          });
          if (!signal.aborted) {
            controller.enqueue(
              encoder.encode(sse({ type: "error", code: e.code, message: e.message })),
            );
          }
        } finally {
          clearTimeout(timer);
          try {
            controller.close();
          } catch {
            // Already closed by disconnect; safe to ignore.
          }
        }
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no",
      },
    });
  } catch (err) {
    const e = err instanceof ModelError ? err : normalizeProviderError(err);
    recordUsage({
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      modelId: modelIdForLog,
      providerId: "unknown",
      status: "error",
      latencyMs: Date.now() - started,
      createdAt: new Date().toISOString(),
    });
    return Response.json({ code: e.code, message: e.message }, { status: e.status });
  }
}
