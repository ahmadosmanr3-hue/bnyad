import { RequestError } from '../http';
import { schemaFor, SYSTEM_INSTRUCTION, type Operation, type Input } from './contract';

export function aiConfig() {
  const model = process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite';
  if (!/^gemini-[a-z0-9.-]+$/.test(model) || model.startsWith('gemini-1.5')) throw new RequestError('AI model configuration needs review.', 503);
  const positive = (key: string, fallback: number, max: number) => {
    const n = Number(process.env[key] ?? fallback);
    if (!Number.isFinite(n) || n <= 0 || n > max) throw new RequestError('AI safeguards are not configured.', 503);
    return n;
  };
  // Explicit rates are required: changing a model must not silently underprice it.
  return { model, key: process.env.GEMINI_API_KEY ?? '', enabled: process.env.AI_ENABLED === 'true',
    inputRate: positive('AI_INPUT_USD_PER_MILLION', 0, 1000), outputRate: positive('AI_OUTPUT_USD_PER_MILLION', 0, 1000),
    budgetMicros: Math.floor(positive('AI_MONTHLY_BUDGET_USD', 0, 10000) * 1_000_000),
    dailyLimit: Math.floor(positive('AI_DAILY_REQUEST_LIMIT', 10, 100)), minuteLimit: Math.floor(positive('AI_REQUESTS_PER_MINUTE', 3, 20)),
    inputLimit: Math.floor(positive('AI_MAX_INPUT_TOKENS', 12000, 32000)), outputLimit: Math.floor(positive('AI_MAX_OUTPUT_TOKENS', 4096, 8192)),
    timeoutMs: Math.floor(positive('AI_TIMEOUT_MS', 25000, 40000)), cacheSeconds: Math.floor(positive('AI_CACHE_TTL_SECONDS', 21600, 86400)) };
}
export type Config = ReturnType<typeof aiConfig>;
export const estimatedCostMicros = (input: number, output: number, config: Pick<Config, 'inputRate' | 'outputRate'>) => Math.ceil(input * config.inputRate + output * config.outputRate);
export function geminiRequest(operation: Operation, prompt: string, input: Input, config: Config) {
  const parts: Record<string, unknown>[] = [{ text: prompt }];
  if (input.image) parts.push({ inlineData: { mimeType: input.image.mimeType, data: input.image.data } });
  // Gemini 2.5 Flash-Lite uses token budgets, not Gemini 3 thinking levels.
  // Keep thinking off for inexpensive development tests; never send both knobs.
  const thinkingConfig = /^gemini-2\.5-flash(?:-|$)/.test(config.model)
    ? { thinkingBudget: 0 } : { thinkingLevel: 'minimal' };
  return { systemInstruction: { parts: [{ text: SYSTEM_INSTRUCTION }] }, contents: [{ role: 'user', parts }],
    generationConfig: { temperature: 0.2, maxOutputTokens: config.outputLimit, responseMimeType: 'application/json', responseJsonSchema: schemaFor(operation), thinkingConfig } };
}
async function limitedJson(response: Response) {
  if (!response.body) throw new RequestError('AI provider returned no response.', 502);
  const reader = response.body.getReader(); let bytes = 0; const chunks: Uint8Array[] = [];
  try {
    while (true) { const { value, done } = await reader.read(); if (done) break; bytes += value.byteLength; if (bytes > 256000) throw new Error(); chunks.push(value); }
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch { await reader.cancel().catch(() => {}); throw new RequestError('AI response was invalid or too large.', 502); }
}
export async function callGemini(operation: Operation, prompt: string, input: Input, config: Config, fetcher: typeof fetch = fetch) {
  if (!config.enabled || !config.key) throw new RequestError('AI is not enabled yet. No request was sent to Google.', 503);
  const body = geminiRequest(operation, prompt, input, config);
  // One total deadline. No retries, fallback-model fanout, tools, search, or URLs.
  const signal = AbortSignal.timeout(config.timeoutMs);
  const base = `https://generativelanguage.googleapis.com/v1beta/models/${config.model}`;
  const post = async (method: string, value: unknown) => {
    const response = await fetcher(`${base}:${method}`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': config.key }, body: JSON.stringify(value), signal, cache: 'no-store', redirect: 'error' });
    if (!response.ok) throw new RequestError(response.status === 429 ? 'AI provider is busy. Try again later.' : 'AI provider is temporarily unavailable.', response.status === 429 ? 429 : 503);
    return limitedJson(response);
  };
  const counted = await post('countTokens', { generateContentRequest: { model: `models/${config.model}`, ...body } });
  if (!Number.isInteger(counted.totalTokens) || counted.totalTokens < 1 || counted.totalTokens > config.inputLimit) throw new RequestError('AI input exceeds the configured token limit.', 413);
  const data = await post('generateContent', body);
  const usage = data.usageMetadata;
  if (!usage || !Number.isInteger(usage.promptTokenCount) || !Number.isInteger(usage.totalTokenCount) || usage.promptTokenCount < 0 || usage.totalTokenCount < usage.promptTokenCount) throw new RequestError('AI usage could not be verified.', 502);
  if (usage.promptTokenCount > config.inputLimit || usage.totalTokenCount - usage.promptTokenCount > config.outputLimit) throw new RequestError('AI provider exceeded the configured token envelope.',502);
  const candidate = data.candidates?.[0];
  if (candidate?.finishReason !== 'STOP') throw new RequestError('AI could not safely complete this request.', 422);
  const content = candidate.content?.parts?.filter((p: any) => !p.thought && typeof p.text === 'string').map((p: any) => p.text).join('');
  let result: unknown;
  try { result = JSON.parse(content); } catch { throw new RequestError('AI returned malformed content.', 502); }
  return { result, inputTokens: usage.promptTokenCount as number, outputTokens: (usage.totalTokenCount - usage.promptTokenCount) as number };
}
