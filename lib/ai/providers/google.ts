import { createGoogleGenerativeAI } from "@ai-sdk/google";
import { streamText, type ModelMessage } from "ai";
import type { ChatMessageInput, ModelConfig } from "../types";
import { ModelError, ERROR_CODES } from "../types";

export async function streamGoogle(
  model: ModelConfig,
  messages: ChatMessageInput[],
  signal: AbortSignal,
) {
  const apiKey =
    process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GOOGLE_API_KEY;
  if (!apiKey) {
    throw new ModelError(ERROR_CODES.MODEL_NOT_CONFIGURED, "Google Gemini API key is not configured on the server.", 503);
  }
  const provider = createGoogleGenerativeAI({ apiKey });
  const result = streamText({
    model: provider(model.providerModelId),
    messages: messages as ModelMessage[],
    maxOutputTokens: model.maxOutputTokens,
    temperature: model.defaultParameters.temperature,
    abortSignal: signal,
  });
  return result;
}
