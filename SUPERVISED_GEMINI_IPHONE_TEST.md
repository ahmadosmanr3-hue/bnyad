# One supervised iPhone food scan — development only

## Approval and scope

The owner approved a cumulative ceiling of **21 Gemini HTTP attempts**, starting
from the existing **19-attempt** ledger. Only one food-photo scan is authorized:
one `countTokens` followed, if successful, by one `generateContent` request to
`gemini-3.5-flash-lite`. No retries, model discovery, fallback or other live AI
operation is permitted. The Free Tier confirmation is retained in the private
backend configuration; no billing changes are made.

This uses the existing isolated local PostgreSQL database, private-LAN HTTPS
server and fictional QA account. Normal password/bearer authentication, DB
Premium grants, explicit AI consent, quotas, usage accounting and full nutrition
validation remain mandatory. There are no migrations or production changes.

## Backend protections

- `vercel-api/scripts/supervised-food-control.ts` requires the explicit owner-
  approved command, an unchanged 19-request ledger, matching private model/key
  configuration and the fictional Premium account. It refuses to replace an
  existing approval. Approval expires after 20 minutes.
- `vercel-api/lib/ai/supervised-food.ts` claims and disables that permission
  **before** provider IO, using the shared exclusive ledger lock. Failure or
  process interruption cannot restore the permission.
- The local server's global network gate allows only the exact approved Google
  model URL, method, credential and ledger position. Exclusive private receipts
  prevent a duplicate token-count or generation request.
- The actual backend endpoint, not merely the CLI, enforces the 21-attempt cap.
  The old CLI keeps its default 20-attempt cap. No counter is reset or refunded.
- AI response validation and consent rechecking occur before any result is sent
  to the app. A supervised request can never return a cached/mock tomato result
  as live output. Other AI operations remain explicitly simulated.

## iPhone build and result identification

The separate `lib/main_local_backend.dart` entry point requires the marked,
non-release iOS development bundle and the existing app-pinned local CA.
Add `--dart-define=LOCAL_ONE_USE_FOOD_TEST=true` only to this one-use test build.
Ordinary local builds reject an armed live backend. Production entry points and
Android are unchanged; no provider credential is embedded in Flutter.

The opted-in client adds a food-only intent marker while retaining normal bearer
authentication. It requires the backend's `google-live` provenance header on
success. Its localized banner changes to live-result/closed or failed/closed.
No automatic request retry is added. Actual native HealthKit remains separate
from fictional server nutrition data; walking calories never alter food targets.

## Private operator workflow

Run from `bnyad-backend/vercel-api`, with a clean local process:

1. Run offline tests and the mock-only local integration checks first.
2. Start the local HTTPS server and install the opted-in development build.
3. Check status with `node --import tsx scripts/supervised-food-control.ts --status`.
4. Only after owner approval and a nonprivate food photo are ready, run
   `node --import tsx scripts/supervised-food-control.ts --arm-owner-approved-21-one-food`.
5. The owner initiates **one** food scan on the iPhone. Do not call the AI route
   from another client, retry an error, or start any live CLI test.
6. Review the private result and method receipts, then run
   `node --import tsx scripts/supervised-food-control.ts --disarm`.
7. Confirm readiness has live access off and record the final cumulative count.

Never commit `.local-development`, `.gemini-development`, local environment
files, database contents, certificates/private keys, photos or credentials.
The public result below must contain only nonprivate food/nutrition information
and request/test counts.

## Verification status

Offline: backend **112/112** tests passed in both repositories, backend type
checks and production build passed; Flutter **316/316** tests and analysis
passed. The real local HTTPS/DB mock integration passed authentication,
Premium/consent enforcement, all four mock AI operations, cache/revocation,
error/rate-limit/quota handling and persistence with the Google ledger unchanged.

Live scan: **not yet performed**. Actual ledger remains 19 and permission remains
unarmed at preparation time. Native installation and supervised scan results
must be recorded after device verification; this document does not claim success.
