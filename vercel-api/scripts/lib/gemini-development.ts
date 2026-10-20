import fs from 'node:fs';
import path from 'node:path';
import { parseEnv } from 'node:util';

export const REQUEST_CAP = 20;
export const TEST_MODEL = 'gemini-2.5-flash-lite';
const allowedModels = [TEST_MODEL, 'gemini-3.5-flash-lite'];
export class DevelopmentStop extends Error {
  constructor(public code: string) { super(code); }
}
type Ledger = { version: 1; requests: number; model?: string; blocked?: string; modelAccessible?: boolean; previousModels?: string[] };

/** Reads only the dedicated private file, never production/Next.js environment files. */
export function privateConfiguration(file: string) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || (stat.mode & 0o077) !== 0) throw new DevelopmentStop('private_file_permissions_required');
  const env = parseEnv(fs.readFileSync(file, 'utf8'));
  if (env.BNYAD_GEMINI_FREE_TIER_CONFIRMED !== 'true') throw new DevelopmentStop('owner_free_tier_confirmation_required');
  const model = env.GEMINI_MODEL;
  if (!model || !allowedModels.includes(model)) throw new DevelopmentStop('requested_model_must_be_reviewed');
  const key = env.GEMINI_API_KEY?.trim();
  if (!key || key.length > 1000 || /[\r\n]/.test(key)) throw new DevelopmentStop('private_key_missing_or_invalid');
  return { key, model };
}

/** Persistent, fail-closed cap across restarts. Every HTTP attempt counts, even
 * metadata/countTokens/failures. An exclusive process lock prevents parallel runs.
 * This is a development harness only; it never changes production safeguards. */
export class DevelopmentBudget {
  private ledger: Ledger;
  private lock: number;
  private ledgerPath: string;
  private lockPath: string;
  readonly modelUrl: string;
  constructor(directory: string, readonly model = TEST_MODEL, private transport: typeof fetch = fetch, approveModelChange = false) {
    if (!allowedModels.includes(model)) throw new DevelopmentStop('requested_model_must_be_reviewed');
    this.modelUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}`;
    fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
    this.ledgerPath = path.join(directory, 'requests.json');
    this.lockPath = path.join(directory, 'session.lock');
    try { this.lock = fs.openSync(this.lockPath, 'wx', 0o600); }
    catch { throw new DevelopmentStop('development_session_locked_review_before_retry'); }
    try {
      this.ledger = fs.existsSync(this.ledgerPath)
        ? JSON.parse(fs.readFileSync(this.ledgerPath, 'utf8'))
        : { version: 1, requests: 0, model };
      if (this.ledger.version !== 1 || !Number.isInteger(this.ledger.requests) || this.ledger.requests < 0 || this.ledger.requests > REQUEST_CAP ||
          (this.ledger.blocked !== undefined && typeof this.ledger.blocked !== 'string')) throw new Error();
    } catch { this.close(); throw new DevelopmentStop('invalid_request_ledger_do_not_reset'); }
    this.ledger.model ??= TEST_MODEL;
    if (this.ledger.model !== model) {
      if (!approveModelChange || (this.ledger.blocked && !['requested_model_unavailable', 'provider_request_or_project_ineligible'].includes(this.ledger.blocked))) {
        this.close(); throw new DevelopmentStop('model_change_requires_owner_approval');
      }
      this.ledger.previousModels = [...(this.ledger.previousModels ?? []), this.ledger.model];
      this.ledger.model = model;
      delete this.ledger.blocked;
      delete this.ledger.modelAccessible;
      this.persist(); // Never reset the original shared HTTP-request count.
    }
  }
  private persist() {
    const fd = fs.openSync(this.ledgerPath, 'w', 0o600);
    try { fs.writeFileSync(fd, JSON.stringify(this.ledger)); fs.fsyncSync(fd); }
    finally { fs.closeSync(fd); }
  }
  get requests() { return this.ledger.requests; }
  get modelAccessible() { return this.ledger.modelAccessible === true; }
  markAccessible() { this.ledger.modelAccessible = true; this.persist(); }
  stop(code: string): never {
    this.ledger.blocked = code; this.persist(); throw new DevelopmentStop(code);
  }
  fetch: typeof fetch = async (input, init) => {
    const url = String(input);
    if (![this.modelUrl, `${this.modelUrl}:countTokens`, `${this.modelUrl}:generateContent`].includes(url) ||
        (url === this.modelUrl ? init?.method !== 'GET' : init?.method !== 'POST')) throw new DevelopmentStop('unexpected_provider_request');
    if (this.ledger.blocked) throw new DevelopmentStop(this.ledger.blocked);
    if (this.ledger.requests >= REQUEST_CAP) throw new DevelopmentStop('twenty_request_cap_reached');
    this.ledger.requests++;
    this.persist(); // Count BEFORE IO; never refund a timeout/uncertain request.
    let response: Response;
    try { response = await this.transport(input, { ...init, redirect: 'error' }); }
    catch { return this.stop('provider_network_error_no_retry'); }
    if (!response.ok) {
      await response.body?.cancel();
      const codes: Record<number, string> = {
        400: 'provider_request_or_project_ineligible', 401: 'provider_key_rejected',
        402: 'provider_payment_required', 403: 'provider_access_denied',
        404: 'requested_model_unavailable', 429: 'provider_quota_unavailable',
      };
      return this.stop(codes[response.status] ?? 'provider_failure_no_retry');
    }
    return response;
  };
  close() { fs.closeSync(this.lock); fs.unlinkSync(this.lockPath); }
}

export async function checkModel(key: string, budget: DevelopmentBudget) {
  if (budget.modelAccessible) return;
  const response = await budget.fetch(budget.modelUrl, {
    method: 'GET', headers: { 'x-goog-api-key': key }, signal: AbortSignal.timeout(15000), cache: 'no-store',
  });
  const data = await response.json();
  if (data.name !== `models/${budget.model}` || !data.supportedGenerationMethods?.includes('generateContent')) {
    budget.stop('requested_model_not_generation_capable');
  }
  budget.markAccessible();
}
