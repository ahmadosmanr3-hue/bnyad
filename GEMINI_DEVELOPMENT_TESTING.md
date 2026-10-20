# Gemini development testing — 20 October 2026

## Observed result, not a production readiness certificate

The owner confirmed Free Tier in AI Studio. A key cannot independently prove the
project's billing tier; no billing account or paid credit was activated here.
The key was entered only in a private, mode-600 file, excluded from Git. Never
paste credentials into chat. Revoke any credential accidentally shared there.

The original gemini-2.5-flash-lite metadata request succeeded, but countTokens
returned HTTP 404 before generation. Do not interpret model metadata visibility
as proof that generation is available. The owner explicitly approved checking
gemini-3.5-flash-lite with available Free Tier quota. No automatic fallback ran.

Total live Google HTTP attempts: **13 of 20**, including metadata, countTokens,
failed calls and generateContent. Five content-generation requests were made:
recipe, first daily plan, food, fridge and one deliberate daily-plan follow-up
after improving planning guidance. No automatic retries, fanout, search, tools,
paid context cache or requests intended to exhaust provider quota were used.

- Ingredient recipe: real response passed the existing ingredient, portion,
  trilingual and catalog-nutrition validators.
- Food photo: recognized public green-tomato photograph; response passed.
  Portion weight is an AI estimate requiring confirmation, not a measured mass.
  This is one simple ingredient, not proof of mixed-dish accuracy.
- Fridge photo: real recognition and one recipe passed; recipe ingredients were
  contained in the recognized list. Recognition is not certified exhaustive.
- Daily planning: **not reliable yet**. First plan totals were 1893 kcal / 140 g
  protein / 149 g carbohydrate / 78 g fat. The follow-up totals were 2151 / 162 /
  233 / 68. Fictional targets were 2000 / 100 / 260 / 60. Both were rejected by
  the unchanged daily calorie/macro tolerances; neither was returned as valid.
  Added explicit planning bounds improved prompt clarity, not reliability.
- All three successful responses had English, Arabic and Sorani fields. Script
  and structure checks passed, but natural Sorani/Arabic wording still requires
  human review. For example, the fridge recipe title needs Sorani wording review.
- Values are computed from the existing catalog and proposed edible grams;
  model-invented nutrition totals are never trusted. Successful results retain
  estimated=true and confirmation_required=true.

The live checks reuse backend buildPrompt, validateInput, callGemini and
validateOutput directly. **They are not authenticated database/Flutter UI
end-to-end tests.** The CLI never imports Prisma, creates accounts, changes
subscriptions, grants premium, or bypasses the normal API's authentication.
The installed offline development apps remain AI-disabled.

## Remaining development and validation

1. Daily planning needs more reliable portion selection/balancing while keeping
   the existing validator and nutritional calculations. Do not make invalid
   plans pass by relaxing tolerances or inventing totals. No further live
   retries were run in this session.
2. Broader public-photo, ambiguous-food, mixed-dish, restriction and language
   review is still required. These three successes do not certify allergy
   safety, portion accuracy or cooking-instruction quality.
3. Real authentication, premium/consent persistence, cache/budget concurrency,
   food logging from results and phone/browser interaction require a separately
   approved isolated backend/database. Those boundaries were tested with mocks,
   not production accounts. Do not apply migrations or connect production to
   complete them without approval.
4. Actual provider quota exhaustion was not induced. HTTP 429, failures,
   timeouts, privacy, malformed content and request-cap behavior use automated
   mock tests; the live HTTP 404 demonstrated a stop without retry.

## Safe local setup

Run only from the authoritative bnyad-backend/vercel-api directory. Do not run
parallel copies from both mirrored repositories or delete/reset the ledger to
replenish the allowance. The local cap cannot account for separate AI Studio
usage or other programs using the key.

Create the ignored .env.gemini-development.local privately (permissions 600):

    GEMINI_API_KEY=<enter privately in your editor, never in chat>
    GEMINI_MODEL=gemini-3.5-flash-lite
    BNYAD_GEMINI_FREE_TIER_CONFIRMED=true

Only set the confirmation after AI Studio shows Free Tier with no active paid
billing. Restrict the key to the Generative Language API where available. This
dedicated file is loaded only by the CLI; ordinary Next.js startup does not
automatically enable it. No key goes into Flutter, dart-defines, URL parameters,
NEXT_PUBLIC variables or Git. Keep normal AI_ENABLED=false and budget defaults
unchanged until a separate safe-environment rollout is approved.

Use Node 22.16+ (Node 24 recommended), existing npm dependencies, and:

    npm run ai:dev -- preflight
    npm run ai:dev -- recipe
    npm run ai:dev -- meal-plan
    npm run ai:dev -- food
    npm run ai:dev -- fridge

Each operation is an explicit action, not an automatic loop. A generation uses
two HTTP attempts (countTokens then generateContent). The persistent
.gemini-development/requests.json counts attempts before network IO and retains
failed/uncertain attempts; an exclusive lock disallows concurrent harness runs.
All provider HTTP failures/network errors block further calls. A stale lock or
corrupt ledger needs manual review, not automatic deletion. The reviewed model
change flag is --approve-model-change, after explicit owner approval; it keeps
the original count and cannot clear quota/payment blocks.

Private results under .gemini-development/results contain only fictional test
data and generated outputs. They are not uploaded or committed. Console output
contains summary/status/token/estimated-cost metadata, never keys, request
headers, photo bytes, raw provider failures or production data. Paid-equivalent
costs are estimates, not charges or authorization to spend.

Photo operations accept only the fixed local test fixtures
.gemini-development/fixtures/food.jpg and fridge.jpg. Use the reviewed public
samples below, JPEG/PNG constraints and metadata stripping from the real
backend. Never replace these with private user photos during this test.

Public sample sources (not committed as binary assets):
- Food: [Tomatoes 1400x1050, Noak Westerberg, public domain](https://commons.wikimedia.org/wiki/File:Tomatoes_1400x1050.jpg).
- Fridge: [Fruits and Vegetables in Refrigerator, Alabama Extension / Margaret Barse, CC0](https://commons.wikimedia.org/wiki/File:Fruits_and_Vegetables_in_Refrigerator_-_50838357566.jpg), 960px preview.

## Source changes and checks

- Gemini 2.5 Flash/Lite request construction uses thinkingBudget=0 instead of
  Gemini 3's thinkingLevel. Existing Gemini 3 request construction is retained.
- Daily-plan prompts expose existing validation bounds and request explicit
  ingredient-based summation. Validators, catalogs and saved targets unchanged.
- Added isolated CLI and automated request-cap/security/config tests. The CLI
  is not imported into production Next.js routes or Flutter entry points.
- Verification: 76 backend tests passed in each repository; type checks and both
  Next.js builds passed. Flutter analysis was clean and all 307 tests passed.
  These automated tests use mocks, never additional live API requests. Remote
  commit hashes are reported separately in the delivery message.

No backend deployment, production write, migration, billing activation, store
publication, mobile design change or step-tracking change occurred.

Official references checked for this task:
- https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash-lite
- https://ai.google.dev/gemini-api/docs/generate-content/thinking
- https://ai.google.dev/gemini-api/docs/generate-content/structured-output
- https://ai.google.dev/gemini-api/docs/pricing
- https://ai.google.dev/gemini-api/docs/billing
