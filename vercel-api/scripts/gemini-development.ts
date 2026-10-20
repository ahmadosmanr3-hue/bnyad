import path from 'node:path';
import fs from 'node:fs';
import { DevelopmentBudget, DevelopmentStop, checkModel, privateConfiguration } from './lib/gemini-development';
import { buildPrompt, validateInput, validateOutput } from '../lib/ai/contract';
import { callGemini, estimatedCostMicros, type Config } from '../lib/ai/provider';
import { RequestError } from '../lib/http';

// Fictional nutrition preferences only, not a production user or health record.
const profile = { dailyCalories: 2000, dailyProtein: 100, dailyCarbs: 260, dailyFat: 60,
  allergies: [], dietaryPattern: 'omnivore', dislikedFoods: [], mealsPerDay: 3 };

async function main() {
  // This file is a CLI, not imported by Next.js or Flutter. No DB/client/session.
  if (process.env.NODE_ENV === 'production' || process.env.VERCEL) throw new DevelopmentStop('local_development_only');
  const { key, model } = privateConfiguration(path.resolve('.env.gemini-development.local'));
  const operation = process.argv[2] ?? 'preflight';
  if (!['preflight', 'recipe', 'meal-plan', 'food', 'fridge'].includes(operation)) throw new DevelopmentStop('unsupported_development_operation');
  const budget = new DevelopmentBudget(path.resolve('.gemini-development'), model, fetch, process.argv[3] === '--approve-model-change');
  try {
    await checkModel(key, budget);
    if (operation === 'preflight') {
      console.log(JSON.stringify({ model, modelAccessible: true, totalHttpAttempts: budget.requests, cap: 20,
        freeTier: 'owner-confirmed; API key cannot independently verify billing', generationTested: false }));
      return;
    }
    if (budget.requests + 2 > 20) throw new DevelopmentStop('insufficient_remaining_http_allowance');
    const image = ['food', 'fridge'].includes(operation) ? {
      mimeType: 'image/jpeg', data: fs.readFileSync(path.resolve(`.gemini-development/fixtures/${operation}.jpg`)).toString('base64'),
    } : undefined;
    const parsed = validateInput({ operation, input: operation === 'recipe'
      ? { ingredients: ['rice', 'chicken', 'tomato'] } : image ? { image } : { cuisine: 'all' } });
    const config: Config = { model, key, enabled: true, inputRate: model === 'gemini-2.5-flash-lite' ? .10 : .30, outputRate: model === 'gemini-2.5-flash-lite' ? .40 : 2.50,
      budgetMicros: 0, dailyLimit: 10, minuteLimit: 3, inputLimit: 12000, outputLimit: 8192,
      timeoutMs: 40000, cacheSeconds: 21600 };
    // Free Tier only. Rates give a paid-equivalent ESTIMATE, not payment approval.
    // DB budget/auth/consent tests remain mocked separately; no DB is connected.
    const response = await callGemini(parsed.operation, buildPrompt(parsed.operation, parsed.input, profile), parsed.input, config, budget.fetch);
    let data: Record<string, any> | undefined, validationError: string | undefined;
    try { data = validateOutput(parsed.operation, response.result, parsed.input, profile); }
    catch (error) { validationError = error instanceof RequestError ? error.message : 'Output rejected'; }
    const summary = { operation, model, validated: !!data, validationError, totalHttpAttempts: budget.requests, cap: 20,
      inputTokens: response.inputTokens, outputTokens: response.outputTokens,
      paidEquivalentEstimateMicros: estimatedCostMicros(response.inputTokens, response.outputTokens, config),
      backendProviderAndContractOnly: true, authenticatedDatabaseAndFlutterEndToEnd: false };
    const report = { ...summary, fictionalProfile: profile, validatedData: data, rejectedOutput: data ? undefined : response.result };
    const directory = path.resolve('.gemini-development/results');
    fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
    fs.writeFileSync(path.join(directory, `${operation}-${Date.now()}.json`), JSON.stringify(report, null, 2), { mode: 0o600, flag: 'wx' });
    console.log(JSON.stringify(summary));
    if (!data) process.exitCode = 1;
  } finally { budget.close(); }
}
main().catch(error => {
  // Never serialize keys, request headers, raw provider errors, or stacks.
  console.error(JSON.stringify(error instanceof DevelopmentStop ? { stopped: error.code }
    : error instanceof RequestError ? { stopped: 'provider_response_rejected', status: error.status, message: error.message }
    : { stopped: 'local_test_failed_review_configuration' }));
  process.exitCode = 1;
});
