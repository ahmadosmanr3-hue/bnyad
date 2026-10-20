import crypto from 'node:crypto';
import { prisma } from '../db';
import { RequestError } from '../http';
import { CONSENT_VERSION, type Operation } from './contract';
import { estimatedCostMicros, type Config } from './provider';

export const cacheKey = (model: string, operation: Operation, prompt: string, image = '') => crypto.createHash('sha256').update(`v1:${model}:${operation}:${prompt}:${image}`).digest('hex');
export function enforceLimits(counts: { minute: number; daily: number; spent: number }, config: Config, reservation: number, cached = false) {
  if (counts.minute >= config.minuteLimit) throw new RequestError('AI rate limit reached. Try again in a minute.', 429, 'ai_rate_limit');
  if (!cached && counts.daily >= config.dailyLimit) throw new RequestError('Your daily AI allowance is exhausted. Try tomorrow (UTC).', 429, 'ai_daily_limit');
  if (!cached && counts.spent + reservation > config.budgetMicros) throw new RequestError('AI spending limit reached. Try again next month.', 429, 'ai_budget_limit');
}
export async function consent(userId: number) {
  const rows = await prisma.$queryRaw<{ version: string; enabled: boolean }[]>`SELECT version, enabled FROM ai_consents WHERE user_id = ${userId}`;
  return { enabled: rows[0]?.enabled === true && rows[0]?.version === CONSENT_VERSION, version: CONSENT_VERSION };
}
export async function setConsent(userId: number, enabled: boolean) {
  return prisma.$transaction(async tx => {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(8141, ${userId}::integer)`;
    await tx.$executeRaw`INSERT INTO ai_consents(user_id, version, enabled) VALUES (${userId}, ${CONSENT_VERSION}, ${enabled}) ON CONFLICT(user_id) DO UPDATE SET version = EXCLUDED.version, enabled = EXCLUDED.enabled, updated_at = NOW()`;
    // Revoke immediately removes reusable results. Usage metadata remains for budget
    // accounting; no prompt, image, health details or raw provider response is logged.
    await tx.$executeRaw`DELETE FROM ai_cache WHERE user_id = ${userId}`;
  });
}
export async function reserve(userId: number, operation: Operation, key: string, config: Config) {
  const id = crypto.randomUUID(), period = new Date().toISOString().slice(0,7);
  const reservation = estimatedCostMicros(config.inputLimit, config.outputLimit, config);
  return prisma.$transaction(async tx => {
    // Global budget and per-user admission are serialized across all instances.
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(8140, 0)`;
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(8141, ${userId}::integer)`;
    const c = await tx.$queryRaw<{ enabled: boolean; version: string }[]>`SELECT enabled, version FROM ai_consents WHERE user_id = ${userId}`;
    if (!c[0]?.enabled || c[0].version !== CONSENT_VERSION) throw new RequestError('AI data-sharing consent is required.', 403);
    const cached = await tx.$queryRaw<{ response: Record<string, any> }[]>`SELECT response FROM ai_cache WHERE user_id = ${userId} AND key = ${key} AND expires_at > NOW()`;
    const active = await tx.$queryRaw<{ count: bigint }[]>`SELECT COUNT(*) AS count FROM ai_usage WHERE user_id = ${userId} AND status = 'reserved' AND created_at > NOW() - INTERVAL '2 minutes'`;
    if (Number(active[0]?.count) > 0) throw new RequestError('An AI request is already running. Please wait.', 429, 'ai_rate_limit');
    const counts = await tx.$queryRaw<{ minute: bigint; daily: bigint }[]>`SELECT COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 minute') AS minute, COUNT(*) FILTER (WHERE status <> 'cached') AS daily FROM ai_usage WHERE user_id = ${userId} AND created_at >= DATE_TRUNC('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'`;
    const budget = await tx.$queryRaw<{ spent: bigint }[]>`SELECT COALESCE(SUM(charged_micros),0)::bigint AS spent FROM ai_usage WHERE budget_period = ${period}`;
    enforceLimits({ minute: Number(counts[0]?.minute ?? 0), daily: Number(counts[0]?.daily ?? 0), spent: Number(budget[0]?.spent ?? 0) }, config, reservation, !!cached[0]);
    const status = cached[0] ? 'cached' : 'reserved', charge = cached[0] ? 0 : reservation;
    await tx.$executeRaw`INSERT INTO ai_usage(id,user_id,operation,model,budget_period,reserved_micros,charged_micros,status,cache_key) VALUES (${id},${userId},${operation},${config.model},${period},${charge},${charge},${status},${key})`;
    await tx.$executeRaw`DELETE FROM ai_cache WHERE user_id = ${userId} AND expires_at <= NOW()`;
    return { id, cached: cached[0]?.response, reservation };
  }, { maxWait: 5000, timeout: 10000 });
}
export async function complete(userId: number, id: string, key: string, response: Record<string, any>, tokens: { inputTokens: number; outputTokens: number }, config: Config) {
  const cost = estimatedCostMicros(tokens.inputTokens, tokens.outputTokens, config);
  return prisma.$transaction(async tx => {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(8141, ${userId}::integer)`;
    await tx.$executeRaw`UPDATE ai_usage SET charged_micros = ${cost}, input_tokens = ${tokens.inputTokens}, output_tokens = ${tokens.outputTokens}, status = 'succeeded' WHERE id = ${id} AND user_id = ${userId}`;
    const c = await tx.$queryRaw<{ enabled: boolean; version: string }[]>`SELECT enabled, version FROM ai_consents WHERE user_id = ${userId}`;
    if (!c[0]?.enabled || c[0].version !== CONSENT_VERSION) return false;
    const expires = new Date(Date.now() + config.cacheSeconds * 1000);
    await tx.$executeRaw`INSERT INTO ai_cache(user_id,key,response,expires_at) VALUES (${userId},${key},${JSON.stringify(response)}::jsonb,${expires}) ON CONFLICT(user_id,key) DO UPDATE SET response = EXCLUDED.response, expires_at = EXCLUDED.expires_at`;
    return true;
  });
}
export async function failed(userId: number, id: string, tokens?: { inputTokens: number; outputTokens: number }) {
  // Timeout/malformed/refusal may still have incurred provider charges. Keep the
  // full reservation, including on process crash. Never refund unknown spending.
  await prisma.$executeRaw`UPDATE ai_usage SET status = 'failed', input_tokens = ${tokens?.inputTokens ?? 0}, output_tokens = ${tokens?.outputTokens ?? 0} WHERE id = ${id} AND user_id = ${userId}`;
}
