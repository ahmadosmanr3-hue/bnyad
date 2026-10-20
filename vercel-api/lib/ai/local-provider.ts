import { RequestError } from '../http';
import { assertLocalDevelopment, localLedgerDirectory } from '../local-development';
import { DevelopmentBudget, DevelopmentStop } from '../../scripts/lib/gemini-development';
import { callGemini, type Config } from './provider';
import type { Input, Operation } from './contract';
import { supervisedFood } from './supervised-food';

/** Used only after normal authentication, Premium, consent and quota admission.
 * Mock output passes the SAME provider parser and final nutrition validators.
 * No prompt/image/profile is sent to Google in mock mode.
 */
export function mockProvider(operation: Operation, prompt: string, scenario = ''): typeof fetch {
  const p = JSON.parse(prompt);
  const names = { en: 'Mock test meal', ar: 'وجبة تجريبية', ku: 'ژەمی تاقیکردنەوە' };
  const text = { en: ['Prepare the listed ingredients. This is a simulated test.'], ar: ['حضّر المكونات المذكورة. هذه محاكاة للاختبار.'], ku: ['پێکهاتە دیاریکراوەکان ئامادە بکە. ئەمە تاقیکردنەوەیەکی دەستکردە.'] };
  const meal = (portions: unknown) => ({ names, instructions: text, portions });
  let raw: unknown;
  if (operation === 'meal-plan') raw = Object.fromEntries(Object.entries(p.dailyMealPortions).map(([slot, portions]) => [slot, meal(portions)]));
  else if (operation === 'food') raw = { names, descriptions: { en: 'Simulated tomato, not photo recognition.', ar: 'طماطم تجريبية، وليست تعرفاً على الصورة.', ku: 'تەماتەی دەستکرد، نەک ناسینەوەی وێنە.' }, portions: [{ id: 'v3', grams: 100 }] };
  else if (operation === 'fridge') raw = { detected_ingredients: { en: ['tomato'], ar: ['طماطم'], ku: ['تەماتە'] }, recipe: meal([{ id: 'v3', grams: 100 }]) };
  else if (operation === 'recipe') raw = meal(p.allowedIngredients.map((f: any) => ({ id: f.id, grams: 100 })));
  else throw new RequestError('This local mock operation is not supported.', 422);
  return (async (url: any) => {
    if (scenario === 'unavailable') throw new RequestError('Mock provider unavailable. No Google request was sent.', 503);
    if (scenario === 'rate-limit') return Response.json({}, { status: 429 });
    if (String(url).endsWith(':countTokens')) return Response.json({ totalTokens: 100 });
    return Response.json({ usageMetadata: { promptTokenCount: 100, totalTokenCount: 300 }, candidates: [
      { finishReason: 'STOP', content: { parts: [{ text: scenario === 'malformed' ? 'invalid json' : JSON.stringify(raw) }] } },
    ] });
  }) as typeof fetch;
}

export async function generateWithLocalGuard(operation: Operation, prompt: string, input: Input, config: Config, scenario?: string, supervisedUserId?: number) {
  if (process.env.APP_ENV !== 'local-iphone') return callGemini(operation, prompt, input, config);
  assertLocalDevelopment();
  localLedgerDirectory();
  if (supervisedUserId !== undefined) {
    if (operation !== 'food') throw new RequestError('Only the supervised food scan is approved.', 422);
    return supervisedFood(prompt, input, config, supervisedUserId);
  }
  if (process.env.BNYAD_LOCAL_AI_MODE === 'mock') return callGemini(operation, prompt, input, config, mockProvider(operation, prompt, scenario));
  // A separate approval and source change are required. This build cannot make
  // any live Google request, even by editing environment variables.
  return withDevelopmentBudget(config.model, async () => {
    throw new RequestError('Live iPhone Gemini testing is not approved. No request was sent.', 503);
  });
}

/** Future supervised live transport: shares the CLI's exclusive lock, existing
 * ledger and fixed 20 HTTP cap. Never used by the mock-only installed build.
 * Preflight refuses to spend the last request on an incomplete generation.
 */
export async function withDevelopmentBudget<T>(model: string, action: (fetcher: typeof fetch) => Promise<T>, transport: typeof fetch = fetch) {
  const directory = localLedgerDirectory();
  let budget: DevelopmentBudget | undefined;
  try {
    budget = new DevelopmentBudget(directory, model, transport);
    if (budget.requests + 2 > 20) throw new RequestError('Insufficient authorized Gemini HTTP requests for a generation.', 429, 'ai_daily_limit');
    return await action(budget.fetch);
  } catch (e) {
    if (e instanceof DevelopmentStop) throw new RequestError('Development Gemini request allowance is blocked. Owner review required.', 429, 'ai_daily_limit');
    throw e;
  } finally { budget?.close(); }
}
