# BNYAD isolated staging setup

Status: source preparation only. No account resources, migrations, seed writes
or deployments are implied by this document. Owner approval is required before
creating resources or applying migrations. Resource creation within existing
included/free limits was approved in this task; migration approval is separate
and must name the verified target. Never purchase, upgrade, or copy production data.

## Isolation and account access

Connect Vercel and Neon so the operator can inspect existing teams, projects and
limits. If doing this manually, use the owner's existing dashboards. Do not paste
API tokens or database connection strings in chat.

Recommended: a NEW Vercel project `bnyad-staging` and NEW EMPTY Neon project
`bnyad-staging`, in the existing accounts and within included limits. Verify limits
before creation; pause if either service requires a charge/upgrade. Record project
IDs, team/organization, region, database name and endpoint host before any writes.
Use a role whose access is limited to the new staging project.

Do not use an ordinary branch of the production database: that normally copies
data. Neon also supports schema-only branches, but an empty independent project
avoids copying users, credentials, health records and live integrations entirely.
Never use production's DATABASE_URL or copy its environment variables wholesale.

References (checked 2026-10-14):
- https://vercel.com/docs/projects
- https://vercel.com/docs/deployments/environments
- https://vercel.com/docs/deployment-protection
- https://neon.com/docs/manage/projects
- https://neon.com/docs/guides/branching-schema-only

## Required staging environment

In the NEW staging Vercel project only:

- Repository: `ahmadosmanr3-hue/bnyad-backend`.
- Source: latest verified `codex/bnyad-stability-2026-10-13` commit, NOT old main.
- Root directory: `vercel-api`; framework Next.js; Node 24.
- Build: `npm run vercel-build`; install: `npm ci`.
- Existing Git auto-deployment is disabled in vercel.json. Keep it disabled and
  deploy deliberately from the verified source to the NEW project only. Do not
  relink the old project, change its Git branch, promote to it or assign its domain.
- `APP_ENV=staging` (leave Vercel's NODE_ENV unchanged).
- `DATABASE_URL`: private pooled connection to the new isolated Neon database,
  including `sslmode=require` or `verify-full`.
- `STAGING_DATABASE_HOST`: independently copy the approved new pooled endpoint
  hostname from Neon Console (no scheme, path or port).
- `STAGING_DATABASE_NAME`: exact new staging database name.
- `STAGING_ENVIRONMENT_ID=bnyad-staging-2026-10-14`: public matching environment
  marker, not a credential. Use the same value in the dev mobile build.
- `AI_ENABLED=false`, `AI_MONTHLY_BUDGET_USD=0`.
- Leave `GEMINI_API_KEY`, RevenueCat REST secrets, Firebase service accounts and
  `OTPIQ_API_KEY` UNSET. Do not reuse production integration credentials.
- `ALLOW_DEMO_OTP=false`. Hosted Next builds intentionally prohibit demo OTP,
  even with APP_ENV=staging. Do not weaken that rule to obtain a test login.
- Use NEW independent strong admin/setup secrets if those tools are required;
  otherwise leave them unset. Never reuse production admin secrets.

The Prisma client refuses staging queries if the approved host/database, TLS,
environment identity or disabled-AI configuration is missing/mismatched.
This is an accident-prevention guard, not proof of isolation: verify actual Neon
project identity and role access independently in the provider console first.

The phone must be able to reach the stable staging API domain directly over
HTTPS. Vercel Authentication on preview URLs may return a hosting login instead
of API JSON. Use a deliberately configured stable URL on the separate staging
project, relying on the API's normal authentication/rate limits. Do not disable
protection on the existing production project and NEVER embed a Vercel bypass
secret in Flutter. Any needed hosting-protection change needs owner approval.
A separate project's default deployment may be called “Production” by Vercel;
it remains BNYAD staging with its own DB/domain, not the existing live project.

## Migration approval gate — do not run yet

Before requesting approval, verify:
1. The exact new Neon project/endpoint/database and scoped role.
2. There are no user or application tables/data in its public schema.
3. The proposed SQL is `vercel-api/db/20261014_staging_empty_bootstrap.sql`,
   generated offline from the current Prisma schema, and the owner has reviewed it.

Ask: “Approve applying the empty staging bootstrap to [project / endpoint /
database] and creating fictional QA data there?” Only after explicit approval,
apply the SQL in THAT project's SQL editor (or a private direct staging connection
with psql ON_ERROR_STOP). The SQL is transactional, refuses a nonempty public
schema, and creates all 17 current application tables, indexes and constraints.
It already includes the auth-rate-limit and AI safeguards tables. Do not execute
the two earlier additive migrations again for this fresh baseline.

For an EXISTING schema-only staging branch, do NOT use the empty bootstrap:
review a schema diff first and select only required additive migrations. A real
database inspection is required to determine that path; never blindly db push.
No migration or seeding command runs during npm install/build/deployment.

## Fictional test account and catalog — after approval only

Use a private local staging-only environment (ignored .env files or a shell secret
prompt). Set `APP_ENV`, approved DB target guards and DATABASE_URL as above plus:

- `STAGING_TEST_DATA_APPROVED=true`
- `STAGING_TEST_PASSWORD`: private random password of at least 16 characters.

Then run in `vercel-api`:

```sh
node --env-file=.env.staging.local --import tsx scripts/create-staging-test-account.ts
# Only after the same staging/test-data approval and target verification:
node --env-file=.env.staging.local --import tsx prisma/seed.ts
```

The account is BNYAD QA / `+9647000000000` / `bnyad-qa@example.test`. Its password
is bcrypt-hashed using normal server authentication; sessions use the normal
login endpoint. It never overwrites an existing account. No OTP SMS is sent and
no auth-bypass endpoint is added. The catalog seed uses repository food data,
not production records. Use fictional profile/meal/weight details.

## Deployment, readiness and iPhone

After schema approval/execution, deploy the verified backend commit manually to
the separate staging project. Check its build source, settings and runtime logs.
GET `https://ACTUAL_STAGING_HOST/api/staging/readiness` must return HTTP 200 JSON:
`environment=staging`, matching `environmentId`, `databaseReady=true`,
`aiEnabled=false`, `contractVersion=1`.
This route reads schema metadata only. It does not prove every column or feature
works; run authenticated functional tests next. It returns 404 outside staging.
No credentials, connection strings, user records or database hostnames are returned.

Build main repo `bnyad` using the dev scheme/entry point:

```sh
flutter pub get
flutter analyze
flutter test
flutter build ios --profile --no-codesign --flavor dev -t lib/main_development.dart \
  --dart-define=STAGING_API_BASE_URL=https://ACTUAL_STAGING_HOST/api \
  --dart-define=STAGING_ENVIRONMENT_ID=bnyad-staging-2026-10-14
```

Follow IOS_DEVELOPMENT.md for development signing, bundle verification, install
and launch. Do not use API_BASE_URL for this entry point: it deliberately accepts
only STAGING_API_BASE_URL and requires the readiness handshake before creating
the app/API client or sending credentials. Missing/invalid config shows a setup
screen, not a misleading login network error. Production/local/invalid URLs and
redirecting or non-staging preflight responses are rejected. AI is disabled on
both sides; push/billing stay disabled; the App Store bundle is unchanged.

## Acceptance checks (not yet run against live staging)

- Mac and iPhone: staging DNS/HTTPS, readiness identity, no hosting login redirect.
- Fictional account: wrong password rejected; correct password signs in; no
  password/token printed to logs.
- Complete onboarding with fictional profile; background/foreground and force
  close/reopen preserve session; authenticated /auth/me succeeds.
- Dashboard/day navigation; log a known food/portion, verify calorie/macros;
  add water and weight; verify intended server-backed records survive reopen.
- Profile updates, language/RTL and themes; manual food/barcode flows where
  compatible; logout and re-login; offline/recovery behavior.
- Confirm neither endpoint URL nor database is production during all test writes.
- AI features must show unavailable without any Google call. SMS/signup,
  push and store purchases are NOT covered without dedicated test integrations.
- Document existing local-only or unsupported flows honestly; do not mark all
  features tested from startup or mocked tests alone.

Resource creation, live schema/migration validation, deployment, account creation,
device login/persistence and nutrition QA remain pending until their access and
approval gates are completed. Nothing in this document authorizes production work.
