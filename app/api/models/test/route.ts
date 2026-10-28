import { NextRequest } from "next/server";
import { findModel, isProviderConfigured } from "@/lib/ai/registry";
import { validateCustomEndpoint } from "@/lib/security";

// POST { modelId } -> { configured, lastResult }
// Never returns a key. A live check is only attempted when a key is present,
// and even then this demo endpoint only reports configuration status
// (a full live call would bill the provider, so it is intentionally NOT
// performed here; the admin page documents the manual test path).
export async function POST(req: NextRequest) {
  let body: { modelId?: string } = {};
  try {
    body = await req.json();
  } catch {
    return Response.json({ code: "INVALID_REQUEST", message: "Invalid JSON." }, { status: 400 });
  }
  const model = body.modelId ? findModel(body.modelId) : undefined;
  if (!model) {
    return Response.json({ code: "MODEL_NOT_FOUND", message: "Unknown model." }, { status: 404 });
  }
  const configured = isProviderConfigured(model.providerId);
  let endpointOk: boolean | null = null;
  if (model.providerId === "openai-compatible") {
    endpointOk = validateCustomEndpoint(process.env.OPENAI_COMPATIBLE_BASE_URL) !== null;
  }
  if (model.providerId === "gateway") {
    endpointOk = validateCustomEndpoint(process.env.AI_GATEWAY_URL) !== null;
  }
  return Response.json({
    modelId: model.modelId,
    providerId: model.providerId,
    configured,
    endpointOk,
    lastResult: configured
      ? "configured — ready to try a real chat request (a live call is billed by the provider, so it is only made from the chat page, not by this status check)"
      : "not_configured — set the provider key / gateway in environment variables (see .env.example)",
    testedAt: new Date().toISOString(),
    note: "No API key is returned by this endpoint.",
  });
}
