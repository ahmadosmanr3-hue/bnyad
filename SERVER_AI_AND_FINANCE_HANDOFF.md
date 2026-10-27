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

## Verified production rollout — 27 October 2026

The owner explicitly approved the additive finance schema and backend rollout. The new tables were created in the verified existing production database without changing existing app/user/subscription data. Backend commit `702bd06fd96ee2dd1e67bfb5b48ff1c84aa81308` is live on `nutrify-api-lovat.vercel.app`, deployment `dpl_GnggrSr12m365cabiTmwyhSAKvSN` (READY).

Production now has `AI_ENABLED=false`, shared daily allowance **9**, one request/minute and the unchanged **$1 total monthly AI spending safeguard**. Readiness returned 200 with the exact deployed revision; unauthenticated finance/AI/subscription access was rejected. Owner-authenticated Admin → Finances showed the new page, quota 9, AI off, $1 safeguard and saved revision 0. No financial entries or archives were created in production during verification.

AI remains disabled; changing the spending budget or enabling it requires separate owner authorization. No new mobile binary, store upload, paid test, credit purchase or billing change was performed for this rollout. See [Apple's verified release status](APPLE_RELEASE_STATUS_20261027.md) for the separate existing iOS submission.

## Checks

169 backend tests, production build/type checks and isolated local PostgreSQL integration passed. The local integration verifies persistence, archive immutability/pagination, stale-save protection, concurrent cross-feature ninth/tenth requests, UTC reset and per-user/month isolation. Fictional-data admin browser save/archive checks passed, including 320px/390px layouts without page overflow. Flutter analysis and all 410 tests passed. No live Gemini requests were made; the original private HTTP ledger remains 21/21. Secrets, financial fixture data and local databases are excluded from Git.
