import { NextRequest } from "next/server";
import { publicRegistry, DEFAULT_MODEL_ID } from "@/lib/ai/registry";

// GET: public registry only. No API keys are ever returned here.
export async function GET() {
  return Response.json({
    models: publicRegistry(),
    defaultModelId: DEFAULT_MODEL_ID,
    demoMode: !process.env.OPENAI_API_KEY && !process.env.ANTHROPIC_API_KEY && !process.env.GOOGLE_GENERATIVE_AI_API_KEY && !process.env.AI_GATEWAY_URL,
    mockEnabled: process.env.IDCX_MOCK_MODEL === "1",
    note: "API keys are server-only and never returned by this endpoint.",
  });
}

// POST: DEMO/LOCAL ONLY admin toggle. This does NOT persist to a database
// and does NOT change server env keys. In production this endpoint must be
// replaced by an authenticated admin route backed by model_configs.
export async function POST(req: NextRequest) {
  let body: { modelId?: string; enabled?: boolean } = {};
  try {
    body = await req.json();
  } catch {
    return Response.json({ code: "INVALID_REQUEST", message: "Invalid JSON." }, { status: 400 });
  }
  if (!body.modelId || typeof body.enabled !== "boolean") {
    return Response.json({ code: "INVALID_REQUEST", message: "modelId and enabled are required." }, { status: 400 });
  }
  return Response.json({
    ok: true,
    demoOnly: true,
    message: "Demo/local toggle accepted in this session only. It is not persisted and does not change server environment keys. Use the admin page note for the production path.",
    modelId: body.modelId,
    enabled: body.enabled,
  });
}
