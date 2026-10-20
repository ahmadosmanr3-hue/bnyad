import { userFromAuthHeader } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { verifiedStoreEntitlement } from '@/lib/subscription';
import { error, json, options, RequestError, safeRoute } from '@/lib/http';
import { buildPrompt, validateInput, validateOutput, validateReplacement, type MealTarget } from '@/lib/ai/contract';
import { aiConfig, estimatedCostMicros } from '@/lib/ai/provider';
import { cacheKey, complete, failed, reserve } from '@/lib/ai/store';
import { generateWithLocalGuard } from '@/lib/ai/local-provider';
export const runtime = 'nodejs';
export const maxDuration = 60;
export const OPTIONS = options;
async function readLimited(req: Request) {
  if (Number(req.headers.get('content-length')) > 1_500_000) throw new RequestError('AI request is too large.',413);
  if (!req.body) throw new RequestError('Missing request body.',400);
  const reader = req.body.getReader(); let size = 0; const chunks: Uint8Array[] = [];
  while (true) { const { value,done } = await reader.read(); if (done) break; size += value.length; if (size > 1_500_000) { await reader.cancel(); throw new RequestError('AI request is too large.',413); } chunks.push(value); }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { throw new RequestError('Invalid JSON body.',400); }
}
export const POST = safeRoute(async (req: Request) => {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.',401);
  // Read trusted DB grants, never request flags or Flutter's preferences.
  const grant = { userId: user.id, active: true, expiresAt: { gt: new Date() } };
  const premium = await prisma.subscription.findFirst({ where: { ...grant, plan: { not: 'store_verified' } } })
    ?? await prisma.subscription.findFirst({ where: { ...grant, plan: 'store_verified' } });
  if (!premium) return error('An active premium subscription is required.',403);
  const config = aiConfig();
  if (!config.enabled || !config.key) return error('AI is not enabled yet. No request was sent to Google.',503);
  if (premium.plan === 'store_verified') await verifiedStoreEntitlement(user.id);
  const { operation, input } = validateInput(await readLimited(req));
  if (!user.profile?.onboarded) return error('Complete your profile before using AI.',422);
  let mealTarget: MealTarget | undefined;
  let planItems: (MealTarget & { slot: string })[] = [];
  if (operation === 'meal' || operation === 'details') {
    const plan = await prisma.mealPlan.findUnique({ where: { userId: user.id }, include: { items: true } });
    const current = plan?.items.find(item => item.slot === input.slot);
    if (!current || plan?.items.length !== 4) return error('A complete saved daily plan is required.',422);
    mealTarget = { calories: current.calories, protein: current.protein, carbs: current.carbs, fat: current.fat };
    planItems = plan.items;
    input.mealName = current.name;
  }
  const prompt = buildPrompt(operation,input,user.profile,mealTarget);
  // Include all restrictions in the cache identity without transmitting health
  // flags/allergy categories to Google; equal eligible lists alone are insufficient.
  const simulated = process.env.APP_ENV === 'local-iphone' && process.env.BNYAD_LOCAL_AI_MODE === 'mock';
  const scenario = simulated ? req.headers.get('x-bnyad-mock-scenario') ?? '' : '';
  const privateContext = JSON.stringify({ image: input.image?.data, allergies: user.profile.allergies, pregnancyStatus: user.profile.pregnancyStatus, planItems, ...(simulated ? { simulated, scenario } : {}) });
  const key = cacheKey(config.model,operation,prompt,privateContext);
  const admission = await reserve(user.id,operation,key,config);
  if (admission.cached) return json({ data: admission.cached, cached: true, estimated: true, ...(simulated ? { simulated: true } : {}) });
  let tokens: { inputTokens: number; outputTokens: number } | undefined;
  try {
    const result = await generateWithLocalGuard(operation,prompt,input,config,scenario);
    tokens = result;
    const data = validateOutput(operation,result.result,input,user.profile);
    if (mealTarget) validateReplacement(data,mealTarget,planItems,input.slot!,user.profile);
    const permitted = await complete(user.id,admission.id,key,data,result,config);
    if (!permitted) return error('AI consent was revoked. The result was discarded.',403);
    // No prompts, photos, profile, provider error body, credentials, or names.
    console.info('ai_usage', { requestId: admission.id, operation, model: config.model, inputTokens: result.inputTokens, outputTokens: result.outputTokens, estimatedCostMicros: estimatedCostMicros(result.inputTokens,result.outputTokens,config), ...(simulated ? { simulated: true } : {}) });
    return json({ data, cached: false, estimated: true, ...(simulated ? { simulated: true } : {}) });
  } catch (e) {
    await failed(user.id,admission.id,tokens);
    if (e instanceof RequestError) throw e;
    throw new RequestError('AI is temporarily unavailable. Please try again later.',503);
  }
});
