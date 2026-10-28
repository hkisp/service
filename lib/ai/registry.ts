import type { ModelConfig, ProviderId, PublicModel } from "./types";

// ---------------------------------------------------------------------------
// Registry notes (honest, by design)
// ---------------------------------------------------------------------------
// The entries below are CONFIGURABLE EXAMPLES, not guarantees. Model IDs,
// availability and context windows change over time at each provider. An
// administrator must confirm a model ID in the provider's own docs / console
// before relying on it. Env overrides (see getRegistry) let an operator
// replace any providerModelId without editing code.
// Env overrides:
//   IDCX_DEFAULT_MODEL            - modelId used when the client asks for none
//   OPENAI_MODEL                  - providerModelId for the default OpenAI entry
//   ANTHROPIC_MODEL, GOOGLE_MODEL, OPENAI_COMPATIBLE_MODEL, AI_GATEWAY_MODEL
// ---------------------------------------------------------------------------

const now = "2026-10-28T00:00:00.000Z";

function base(partial: Omit<ModelConfig, "createdAt" | "updatedAt">): ModelConfig {
  return { ...partial, createdAt: now, updatedAt: now };
}

export const DEFAULT_MODEL_ID = process.env.IDCX_DEFAULT_MODEL || "openai-gpt-5-mini";

const REGISTRY: ModelConfig[] = [
  base({
    modelId: "openai-gpt-5-mini",
    displayName: "GPT-5 mini (example)",
    providerId: "openai",
    providerModelId: process.env.OPENAI_MODEL || "gpt-5-mini",
    enabled: true,
    supportsStreaming: true,
    supportsImages: false,
    supportsTools: false,
    contextWindow: 400000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  base({
    modelId: "openai-gpt-4o-mini",
    displayName: "GPT-4o mini (example)",
    providerId: "openai",
    providerModelId: "gpt-4o-mini",
    enabled: true,
    supportsStreaming: true,
    supportsImages: true,
    supportsTools: false,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  base({
    modelId: "claude-sonnet-4-5",
    displayName: "Claude Sonnet 4.5 (example)",
    providerId: "anthropic",
    providerModelId: process.env.ANTHROPIC_MODEL || "claude-sonnet-4-5",
    enabled: true,
    supportsStreaming: true,
    supportsImages: true,
    supportsTools: false,
    contextWindow: 200000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  base({
    modelId: "gemini-2-5-flash",
    displayName: "Gemini 2.5 Flash (example)",
    providerId: "google",
    providerModelId: process.env.GOOGLE_MODEL || "gemini-2.5-flash",
    enabled: true,
    supportsStreaming: true,
    supportsImages: false,
    supportsTools: false,
    contextWindow: 1000000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  base({
    modelId: "openai-compatible-custom",
    displayName: "Custom OpenAI-compatible",
    providerId: "openai-compatible",
    providerModelId: process.env.OPENAI_COMPATIBLE_MODEL || "custom-model",
    enabled: true,
    supportsStreaming: true,
    supportsImages: false,
    supportsTools: false,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  base({
    modelId: "gateway-default",
    displayName: "AI Gateway (configured model)",
    providerId: "gateway",
    providerModelId: process.env.AI_GATEWAY_MODEL || "gateway-default-model",
    enabled: true,
    supportsStreaming: true,
    supportsImages: false,
    supportsTools: false,
    contextWindow: 128000,
    maxOutputTokens: 4096,
    defaultParameters: { temperature: 0.7 },
  }),
  // Test-only mock. Never enabled unless IDCX_MOCK_MODEL=1 (see router.ts).
  base({
    modelId: "mock-test",
    displayName: "Test Mock (testing only)",
    providerId: "mock",
    providerModelId: "mock-test",
    enabled: false,
    supportsStreaming: true,
    supportsImages: false,
    supportsTools: false,
    contextWindow: 8192,
    maxOutputTokens: 1024,
    defaultParameters: { temperature: 0.7 },
  }),
];

export function getRegistry(): ModelConfig[] {
  const list = REGISTRY.map((m) => ({ ...m }));
  if (process.env.IDCX_MOCK_MODEL === "1") {
    const mock = list.find((m) => m.providerId === "mock");
    if (mock) mock.enabled = true;
  }
  return list;
}

export function findModel(modelId: string): ModelConfig | undefined {
  return getRegistry().find((m) => m.modelId === modelId);
}

export function isProviderConfigured(providerId: ProviderId): boolean {
  switch (providerId) {
    case "openai":
      return Boolean(process.env.OPENAI_API_KEY);
    case "anthropic":
      return Boolean(process.env.ANTHROPIC_API_KEY);
    case "google":
      return Boolean(
        process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GOOGLE_API_KEY,
      );
    case "openai-compatible":
      return Boolean(
        process.env.OPENAI_COMPATIBLE_API_KEY &&
          process.env.OPENAI_COMPATIBLE_BASE_URL,
      );
    case "gateway":
      return Boolean(
        process.env.AI_GATEWAY_URL && process.env.AI_GATEWAY_API_KEY,
      );
    case "mock":
      return process.env.IDCX_MOCK_MODEL === "1";
    default:
      return false;
  }
}

export function configSourceFor(providerId: ProviderId): PublicModel["configSource"] {
  if (providerId === "mock") return "mock";
  if (providerId === "gateway") return isProviderConfigured(providerId) ? "gateway" : "none";
  return isProviderConfigured(providerId) ? "env" : "none";
}

export function publicRegistry(): PublicModel[] {
  return getRegistry().map((m) => ({
    ...m,
    configured: isProviderConfigured(m.providerId),
    configSource: configSourceFor(m.providerId),
  }));
}

export function providerLabel(providerId: ProviderId): string {
  switch (providerId) {
    case "openai":
      return "OpenAI";
    case "anthropic":
      return "Anthropic Claude";
    case "google":
      return "Google Gemini";
    case "openai-compatible":
      return "OpenAI-compatible";
    case "gateway":
      return "AI Gateway";
    case "mock":
      return "Test Mock";
  }
}
