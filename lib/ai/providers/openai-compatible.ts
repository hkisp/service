import { createOpenAI } from "@ai-sdk/openai";
import { streamText, type ModelMessage } from "ai";
import type { ChatMessageInput, ModelConfig } from "../types";
import { ModelError, ERROR_CODES } from "../types";
import { validateCustomEndpoint } from "../../security";

export async function streamOpenAICompatible(
  model: ModelConfig,
  messages: ChatMessageInput[],
  signal: AbortSignal,
) {
  const apiKey = process.env.OPENAI_COMPATIBLE_API_KEY;
  const rawBase = process.env.OPENAI_COMPATIBLE_BASE_URL;
  const baseURL = validateCustomEndpoint(rawBase);
  if (!apiKey || !baseURL) {
    throw new ModelError(
      ERROR_CODES.MODEL_NOT_CONFIGURED,
      "OpenAI-compatible endpoint or key is not configured, or the endpoint failed the public-HTTPS safety check.",
      503,
    );
  }
  const provider = createOpenAI({ apiKey, baseURL });
  const result = streamText({
    model: provider(model.providerModelId),
    messages: messages as ModelMessage[],
    maxOutputTokens: model.maxOutputTokens,
    temperature: model.defaultParameters.temperature,
    abortSignal: signal,
  });
  return result;
}
