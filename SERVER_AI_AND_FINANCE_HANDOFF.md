# Server AI allowance and monthly finances — 26 October 2026

No Flutter UI, nutrition formula, subscription, localization, HealthKit, Health Connect or native signing code changes are required for this work. Existing clients that call the authenticated backend inherit its quota after the backend rollout; no new mobile binary is needed for this policy/admin change.

The implementation is in the official **backend repository**, not this repository's historical backend mirror:

- Branch: `codex/bnyad-production-repair-2026-10-25`
- Backend commit: `702bd06fd96ee2dd1e67bfb5b48ff1c84aa81308`
- [Backend handoff, setup and verification](https://github.com/ahmadosmanr3-hue/bnyad-backend/blob/702bd06fd96ee2dd1e67bfb5b48ff1c84aa81308/ADMIN_FINANCE_HANDOFF.md)

## Behavior after approved backend rollout

One shared allowance of nine admitted AI requests per account per UTC day across every AI feature, including cached responses and failed admitted attempts. Photos, daily meal generation, individual regeneration, ingredient recipes, fridge analysis and AI body-fat estimates use the same pool. Local body-fat calculations, tracking, steps and barcode lookup do not call Gemini and are outside this AI allowance. Normal authentication, Premium, consent, rate and global spending safeguards remain enforced.

Admin → Finances stores monthly USD line items for sales, expenses, commissions, taxes, refunds and bank/FX costs, differentiating actual statements from estimates. AI usage is read from the server's existing ledger. Statements and invoices are entered manually; a Premium grant is not automatically counted as revenue. Next-month planning calculates funding requirements using explicit assumptions and a dated manually checked credit balance. This page cannot purchase credit or enable AI.

Saved months can be archived at any time. Immutable server-side snapshots preserve figures and assumptions even after later edits, with CSV/JSON exports and access to old months/archive pages. Tax rates are not guessed or filed; enter actual statements and accountant-confirmed amounts without duplicate deductions.

## Rollout hold / configuration

At verification time production still had `AI_ENABLED=false`, daily allowance **3**, one request/minute and a **$1 total monthly AI spending safeguard**. New code is pushed but not yet deployed. Production rollout needs approval for the two additive finance tables and backend deployment with `AI_DAILY_REQUEST_LIMIT=9`. Keep AI disabled and the existing global spending cap unchanged. Do not apply production migrations, enable Gemini, change billing or publish mobile updates as part of this handoff without the appropriate owner authorization.

## Checks

169 backend tests, production build/type checks and isolated local PostgreSQL integration passed. The local integration verifies persistence, archive immutability/pagination, stale-save protection, concurrent cross-feature ninth/tenth requests, UTC reset and per-user/month isolation. Fictional-data admin browser save/archive checks passed, including 320px/390px layouts without page overflow. Flutter analysis and all 410 tests passed. No live Gemini requests were made; the original private HTTP ledger remains 21/21. Secrets, financial fixture data and local databases are excluded from Git.
