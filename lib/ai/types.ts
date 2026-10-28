// Unified model types. Frontend code never sees provider internals or API keys.
export type ChatRole = "system" | "user" | "assistant";

export interface ChatMessageInput {
  role: ChatRole;
  content: string;
}

export type ProviderId =
  | "openai"
  | "anthropic"
  | "google"
  | "openai-compatible"
  | "gateway"
  | "mock";

export interface ModelConfig {
  modelId: string;
  displayName: string;
  providerId: ProviderId;
  providerModelId: string;
  enabled: boolean;
  supportsStreaming: boolean;
  supportsImages: boolean;
  supportsTools: boolean;
  contextWindow: number;
  maxOutputTokens: number;
  defaultParameters: { temperature?: number; topP?: number };
  createdAt: string;
  updatedAt: string;
}

/** Public view of a model: no keys, only whether it is configured. */
export interface PublicModel extends ModelConfig {
  configured: boolean;
  /** Gateway models are configured when the gateway itself is configured. */
  configSource: "env" | "gateway" | "mock" | "none";
}

export interface StreamUsage {
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
}

export interface StreamChunk {
  type: "delta" | "done" | "error";
  text?: string;
  usage?: StreamUsage | null;
  code?: string;
  message?: string;
}

export class ModelError extends Error {
  code: string;
  status: number;
  constructor(code: string, message: string, status = 400) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

export const ERROR_CODES = {
  MODEL_NOT_FOUND: "MODEL_NOT_FOUND",
  MODEL_NOT_CONFIGURED: "MODEL_NOT_CONFIGURED",
  MODEL_DISABLED: "MODEL_DISABLED",
  INVALID_REQUEST: "INVALID_REQUEST",
  RATE_LIMITED: "RATE_LIMITED",
  PROVIDER_ERROR: "PROVIDER_ERROR",
  TIMEOUT: "TIMEOUT",
  ABORTED: "ABORTED",
  UNSAFE_ENDPOINT: "UNSAFE_ENDPOINT",
} as const;
