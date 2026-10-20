# Daily meal-plan repair — 20 October 2026

## Exact failure diagnosis

The two original real responses were rejected correctly. Fictional daily targets
were 2000 kcal, 100 g protein, 260 g carbohydrate and 60 g fat. The existing
validator allows ±20% calories and ±30% macros: 1600–2400 kcal, 70–130 g protein,
182–338 g carbohydrate and 42–78 g fat.

- First response: 1893 kcal / 140 g protein / 149 g carbohydrate / 78 g fat.
  Protein exceeded the permitted maximum by 10 g; carbohydrate missed the
  minimum by 33 g. Calories and fat passed.
- Second response: 2151 kcal / 162 g protein / 233 g carbohydrate / 68 g fat.
  Protein exceeded the permitted maximum by 32 g; the other totals passed.

These are catalog-derived totals, using the existing edible portion weights
and per-meal rounding, not the model's claimed totals. The first response chose
150 g eggs, 180 g chicken, 160 g salmon and 150 g yogurt, without enough
carbohydrate. The second chose 220 g chicken, 200 g salmon and 200 g yogurt,
again overshooting protein.

The target combination is consistent: macro energy is 1980 kcal, close to the
2000 kcal target. Regression tests demonstrate feasible catalog portions at the
same targets. There is no evidence that the tolerances or catalog arithmetic
caused these failures. We cannot inspect the model's internal arithmetic; the
observable failure was unconstrained portion allocation. The whole-day prompt
also included an ambiguous single-meal 700 kcal target. That field is now absent
for daily plans. Cooked versus dry preparation is clarified, but was not proven
to be the cause of either original failure.

## Repair and unchanged safeguards

The server prepares bounded, integer ingredient quantities from the existing
allergy/diet/dislike-filtered catalog. A small deterministic numerical search
balances the existing catalog nutrient vectors against the existing saved
targets. Every candidate must pass the unchanged full output validator before
Google is contacted. This is local arithmetic, not a provider retry.

Gemini receives those validated quantities and supplies names and cooking
instructions in English, Arabic and Kurdish Sorani. Its JSON schema fixes each
slot's catalog IDs, quantities and ingredient count. The prompt requires exact
portions, no hidden additions, appropriate cooked/dry preparation and ONE day
only. Provider output that alters the portions is rejected without retry.
The final response then passes the existing full nutrition, allergy, dietary,
language and output validators again. Internal feasibility placeholder text is
never returned to users or used as a recipe fallback.

No calorie/macro calculation, tolerance, allergy filter, saved profile, food
allowance, subscription, authentication, consent, quota, UI, or HealthKit/Health
Connect implementation was changed. Walking calories still do not increase food
allowance. No invalid response is post-scaled and no invented totals are trusted.

The bounded planner deliberately has a limited ingredient-role palette.
It may reject some feasible unusual profiles rather than relax safety checks;
a rejection is not proof that no possible diet exists. Culinary variety and
meal composition quality remain areas for improvement. This is not a medical
or certified allergy-safe meal service; labels and cross-contamination need
individual review.

## Offline and live verification

Offline checks ran before new Google requests:

- 98 backend tests pass, including 22 new daily-planning regression cases.
- Both original failed plans still fail for their original reasons.
- Fourteen fictional profiles cover ordinary, smaller/larger calorie targets,
  vegan, vegetarian, pescatarian, halal, kosher, multiple allergies, low-carb,
  keto, pregnancy and dislikes. A separate 42-profile calorie/diet sweep passes.
- Exact schema construction, malformed/altered portions, hidden ingredients,
  missing languages, inconsistent targets and no-retry behavior are covered.
- Existing authentication, premium, consent, quota, rate-limit, failure and
  provider request-cap tests remain in the suite.
- Flutter analysis is clean and all 307 Flutter tests pass. No Dart files changed.
- Both mirrored API repositories pass all 98 tests, TypeScript checking and the
  Next.js production build. Building did not deploy or apply database migrations.

Three explicit real gemini-3.5-flash-lite generations then passed all existing
validators, with all four daily slots and en/ar/ku names/instructions:

- Standard: targets 2000 / 100 / 260 / 60; actual 1971 / 100 / 262 / 61.
- Vegan: targets 2000 / 90 / 270 / 65; actual 1948 / 90 / 274 / 65.
- Multiple allergies (milk, egg, gluten, peanuts, tree nuts):
  targets 2000 / 100 / 260 / 60; actual 1990 / 100 / 261 / 60.

Values above are kcal / protein g / carbohydrate g / fat g. All retain
estimated=true and confirmation_required=true. Language/script structure passes;
natural Arabic/Sorani wording and cooking quality still require human review.
Do not equate three successes with a statistical reliability guarantee.

Each live generation consumed countTokens and generateContent, with no automatic
retries. Total usage increased from 13 to **19 of the original 20 HTTP attempts**.
No more full generation fits this allowance. Stop rather than reset the ledger,
switch repositories to gain requests, or start an unattended retry loop.

These are direct backend provider/contract tests with fictional profiles.
They are not authenticated database-to-Flutter end-to-end tests. Broader device
AI interaction, premium/consent persistence and logging require an approved
isolated backend/database. Do not connect production or apply migrations to
complete them. Existing installed development apps remain AI-disabled.

## Source and handoff

Both official repositories retain the same mirrored API implementation:

- vercel-api/lib/ai/daily-plan.ts: bounded portion preparation and exact-output guard.
- vercel-api/lib/ai/contract.ts: daily prompt and constrained structured schema.
- vercel-api/lib/ai/provider.ts: schema context and provider-output enforcement.
- vercel-api/tests/daily-plan.test.ts: reproduction and regression coverage.
- vercel-api/scripts/gemini-development.ts: fictional profile selection.

No new dependency, environment variable or database migration is required.
Keep existing AI_ENABLED=false outside the separately approved private harness.
No key is sent to Flutter or committed. The private environment file, ledger and
generated results stay ignored and must not be copied between repositories.

For a future separately approved request allowance, the existing authoritative
backend harness supports explicit meal-plan invocations with --profile=standard,
--profile=vegan or --profile=allergy. Do not run these again under the current
19/20 ledger. Free Tier status is the owner's AI Studio confirmation; the API key
alone does not independently establish billing status. Billing remains off.

Release developer: pull the reported commits, use existing dependencies, run
npm test, npm run typecheck and npm run build in vercel-api, and run Flutter
analysis/tests in the main repository. Deployment and mobile publishing remain
your responsibility after separate approval. Git-triggered Vercel deployment
remains disabled. Nothing was deployed, migrated, purchased or published here.

