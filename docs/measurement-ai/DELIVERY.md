# Measurement and AI delivery — 2026-11-16

Branch in both official repositories: `codex/bnyad-food-system-phase-2`.

Tested implementation commits (followed only by this documentation handoff):

- Flutter: `29ddec73841db775dffa260a83e0cbf79f3244a9` — https://github.com/ahmadosmanr3-hue/bnyad/commit/29ddec73841db775dffa260a83e0cbf79f3244a9
- Backend: `a80e1a5bb84f9f5b8c12a9a614030c5fd14f7dd8` — https://github.com/ahmadosmanr3-hue/bnyad-backend/commit/a80e1a5bb84f9f5b8c12a9a614030c5fd14f7dd8

The branch tip includes this handoff. Pull both branches; the completion message records the final remote tip hashes. No secrets, databases, private environment files, generated app packages or raw debug logs are included.

## Verification

- PASS: Flutter analysis; 492 Flutter tests.
- PASS: 202 backend tests, TypeScript, Prisma generation and Next.js production build.
- PASS: six native emulator/simulator size configurations, English/Arabic/Sorani and light/dark themes. 306 captures; 20 representative native screenshots are committed in the main repository.
- PASS: actual system photo pickers on Android/iOS and second-photo review, retake, remove and cancel. Android camera permission/activity launch checked; iOS Simulator reports camera unavailable and remains usable.
- Not established: physical-camera capture, real Gemini accuracy, weighed-portion error, model comparison, live latency/cost, new physical Health/push/OTP/purchase checks. No mock is counted as a real recognition result.

Main evidence: [screenshots](https://github.com/ahmadosmanr3-hue/bnyad/tree/29ddec73841db775dffa260a83e0cbf79f3244a9/docs/measurement-ai), [full report](https://github.com/ahmadosmanr3-hue/bnyad/blob/29ddec73841db775dffa260a83e0cbf79f3244a9/BNYAD_MEASUREMENT_AND_AI_IMPROVEMENT_REPORT.md).

## Setup and release hold

1. Flutter: `flutter pub get`, `flutter analyze`, `flutter test`. Added dependency: Flutter SDK `integration_test` in dev dependencies only. No new production dependency.
2. Backend: `cd vercel-api`, `npm ci`, `npm test`, `npm run typecheck`, `npm run build`. No new environment variables, backend packages or database migrations.
3. After explicit rollout approval, deploy the backward-compatible backend first, then smoke-test authenticated legacy and v2 requests before releasing the client. Existing auth, Premium, consent, budget, model/key and daily-quota settings remain in force. Keep keys server-only.
4. Retain the previous known-good backend deployment for rollback. Use existing AI disable control if v2 fails; never substitute mocks in production.
5. Obtain separate live-test request approval before evaluating Gemini. The exhausted prior development ledger was not altered; zero new live requests were made.
6. Physical camera/Health regression testing and release-candidate verification remain release checks. Shipping iOS remains iPhone-only; full-width iPad checks used a simulator-only device-family override, not an expanded store support declaration.
7. No production rollout, database writes/migrations or store upload/submission/publication was performed. Final store release approval is still required; allocate the next unused version/build then.

The 350 blocked food candidates and unresolved research are preserved. No catalog IDs, nutrient records, historical meal logs or favorites were replaced by this work.
