import { createOpenAI } from "@ai-sdk/openai";
import { streamText, type ModelMessage } from "ai";
import type { ChatMessageInput, ModelConfig } from "../types";
import { ModelError, ERROR_CODES } from "../types";
import { validateCustomEndpoint } from "../../security";

/**
 * Gateway mode (Mode A): an OpenAI-compatible gateway configured by
 * AI_GATEWAY_URL + AI_GATEWAY_API_KEY. The gateway itself maps the
 * providerModelId to an upstream model; IDCX never invents that mapping.
 */
export async function streamGateway(
  model: ModelConfig,
  messages: ChatMessageInput[],
  signal: AbortSignal,
) {
  const apiKey = process.env.AI_GATEWAY_API_KEY;
  const baseURL = validateCustomEndpoint(process.env.AI_GATEWAY_URL);
  if (!apiKey || !baseURL) {
    throw new ModelError(
      ERROR_CODES.MODEL_NOT_CONFIGURED,
      "AI Gateway URL or key is not configured, or the URL failed the public-HTTPS safety check.",
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
