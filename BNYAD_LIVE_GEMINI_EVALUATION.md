# BNYAD live Gemini food evaluation — 2026-11-16

Status: **PREPARATION PASSED; LIVE EVALUATION NOT EXECUTED.** Genuine overhead/side views of all three unchanged food portions are not available. The owner requested online photo research; candidates were inspected, but the required complete set was not established. No food recognition, portion-accuracy or single-versus-two-photo improvement is claimed.

## Actual attempts, money and authorization

- New Gemini API attempts: **0** (0 countTokens, 0 generateContent).
- New food scans executed: **0 / 6**.
- Actual existing cumulative ledger: **21**, unchanged, private mode 0600. Approved cumulative ceiling: **33** (at most 12 additional attempts).
- Estimated cost incurred by this evaluation: **$0.00**. Approved maximum estimated total: **$0.10**.
- Previous one-use food approval: **disabled/disarmed and expired**. New paired approval: **not prepared/not armed**; no private runtime grant was created.
- Verified actual local network gate with a mocked transport: **request denied; 0 requests forwarded; original ledger bytes unchanged**. This was not a Gemini request or a test of current Google project quota.
- Public documentation and recipe-page downloads are research traffic, not Gemini API calls. No production deployment, billing change, database migration, mobile install or store submission occurred in this evaluation preparation.

## Environment and model checks

Verified the existing isolated environment: APP_ENV local-iphone, mock default mode, PostgreSQL host 127.0.0.1, port 55439 and database bnyad_local_iphone_20261020. The database was reachable; the existing fictional QA user is onboarded/adult, has active server Premium and current enabled consent. These checks were read-only. No production account/database was queried or changed.

The private backend-only Gemini configuration names **gemini-3.5-flash-lite**; a key is present in its mode-0600 local file, and the server's input/output rates are $0.30/$2.50 per million tokens. No key was printed, moved to Flutter or committed. The official model page confirms image input and structured-output support: https://aistudio.google.com/docs/models/gemini-3.5-flash-lite . Official Standard rates were reconfirmed: https://aistudio.google.com/docs/pricing#gemini-3.5-flash-lite . Actual current project eligibility/quotas were not probed with an additional model/metadata request; any failure in the first authorized token-count call must stop without retry.

The controller caps each scan at 12000 input/4096 output tokens. Its maximum reserved generation cost is $0.01384 per scan; six such reservations total $0.08304, within the $0.10 ceiling. A typical assumed 4000-token single/6000-token pair input and 800 output tokens gives about $0.021 for all six scans. These are prospective estimates, not measured costs or a Google billing-account limit.

## Photographs researched and exclusions

No photographs have been sent to Gemini. No candidate has an independently weighed edible-portion reference. Author recipe calculations and generic serving weights are not measured ground truth.

1. **Kurdish chicken biryani** — https://sourandsweets.com/kurdish-biryani-iraqi-biryani-recipe/ . Inspected its plated biryani photograph and a second photograph with food lifted on a spoon above the plate. The second changes the portion and focuses on a spoonful, so it is not the required overhead/side pair of an unchanged portion. Excluded.
2. **Iraqi dolma/yaprax** — https://www.hungrypaprikas.com/iraqi-dolma/ . Inspected the two patterned-plate photographs. They are similar overhead compositions with framing/zoom changes; neither establishes the required distinct side/depth view. Excluded as a paired evaluation case.
3. **Arabic chicken shawarma** — https://www.pipercooks.com/chicken-shawarma-plate/ . Inspected an overhead and a low-angle plate photograph. The arrangement appears visually consistent; retained as a candidate. This is visual inference, without independent author confirmation of an unchanged portion or a measured mass. It does not fill the missing pairs for the other dishes.

Additional Kurdish biryani/dolma sources were reviewed (Hilda's Kitchen, Bidfood, Laroot World, The Flaming Potato and Coolinarika); some image/page requests were inaccessible or rate-limited. No protections were bypassed. Unrelated meals, crop variants, food moved to a spoon or different cooking stages were not relabeled as genuine matching views.

Source URLs and detailed review status are saved in backend `vercel-api/evaluation/online-image-review.json`. Candidate images were inspected locally; copyrighted recipe photographs were not redistributed in Git, added to the app/catalog or treated as verified nutrition data. Existing openly licensed research fixtures and attribution remain preserved.

## Single-photo versus paired results

- Biryani Test A and Test B: **not run**, missing a valid genuine pair.
- Dolma Test A and Test B: **not run**, missing a valid side/depth view of the unchanged portion.
- Shawarma Test A and Test B: **not run**, candidate review and complete approved three-food input set remain pending.
- Food/ingredient correctness, regional confusions, hallucinated ingredients, estimates in grams, calorie/macronutrient outputs, translations, latency, token consumption and paired-view gain: **unverified / no observations**, not zero-error results.
- Portion-estimation error: **unscored**, because no independently measured references exist.

The original six-scan design and allowance are preserved. It was not silently replaced by unpaired online-photo testing. The pilot, when completed, will be a qualitative comparison of three meals, not evidence of general recognition accuracy.

## Implemented local admission controller

Backend implementation commit: `e76b02207c08e77947ce76d84cd0c1da3cdb5c01` on branch `codex/bnyad-food-system-phase-2`. Main application code remains at its already-tested implementation; pre-follow-up main handoff tip was `0618f2dea56895a03a6c43d9dadebc3c667dd743`. The final documentation-only delivery tips are reported in the chat completion and can be verified with git ls-remote.

- The regular `/api/ai/generate` handler requires normal session authentication, server Premium, an adult onboarded profile, consent/revocation, rate/daily/monthly quotas and unchanged nutrition/allergy validation. The local evaluation header does not bypass them.
- A one-time private approval binds the fictional user, exact model/rates, six sanitized image-digest/view cases, 21→33 ledger scope, maximum six scans and at most $0.10. It expires after one hour. No environment switch alone activates it.
- An exclusive shared process lock durably claims each case and reserves two HTTP attempts plus worst-case estimated cost **before IO**. Each attempted request increments the original ledger before IO; failures/timeouts are never refunded. Reserved and observed attempts/costs must reconcile with saved evidence, so resetting/copying an older ledger is rejected.
- A global local-server network gate allows only the claimed model's exact countTokens→generateContent sequence and one-use method receipts. Extra requests, metadata GETs, duplicate methods, wrong images/models, ground-truth measurements, unsupported operations and fallback calls are blocked. An unexpected or failed network request stops the pilot even if an intermediate caller catches the exception.
- Successful actual token cost replaces its reservation; unknown failures retain the full reservation. Limits are ceilings, not targets. Current provider parsing, structured nutrition safety and allergy checks remain unchanged.
- Cache results cannot count as supervised live evidence. Validated response data is retained privately only after the endpoint's final consent check; photo bytes, prompts, keys, sessions and profiles are not saved in the approval record. Independently measured truth is stored separately and withheld from model inputs.
- Live transport automatically closes after each observation; the next case needs explicit arming. It remains closed after completion, rejection, quota exhaustion, revocation or expiry. A crash leaves a claimed case and/or lock for review rather than reusable allowance. The old 20/21 CLI and one-use caps remain unchanged.
- Private control script supports status, reviewed preparation, one-case arming and disarming; it makes **no provider calls**. Preparation refuses missing/unreviewed pairs or an existing approval. Instructions: backend `vercel-api/evaluation/PAIRED_EVALUATION_CONTROL.md`.

No prompt, model, food aliases or nutrition values were changed to improve a score. There is no live error evidence yet to justify a recognition-quality change.

## Completed tests and their limits

- **225 backend tests PASS**, including 15 new controller tests and 8 tests invoking the actual API handler with injected mocked database/provider dependencies. Tests cover request and cost reservation, 12-attempt/6-scan cap, cumulative 33, no retries, forced failures, invalid responses, expiry, duplicate/direct calls, concurrency, altered images/known weights, ledger reset rejection, auth/Premium/consent, daily/minute/monthly limits, consent revocation and disarm.
- **TypeScript PASS** and **Next.js production build PASS**.
- **492 Flutter tests PASS** and **Flutter analysis PASS**, no issues. No Flutter production code, UI, step tracking or Android/iOS configuration was changed.
- Tests use synthetic image fixtures, fake provider responses, a mocked database and temporary fixture ledgers. Simulated 12-call runs never consumed the real 21-attempt ledger or proved recognition accuracy. The actual existing database was separately checked read-only, and the actual private gate was checked with a mocked, zero-forwarding transport.

## Remaining blocker and next action

Obtain genuine matching photographs for all three dishes (or source links that clearly establish them). Each case needs a full overhead view and a genuine side/depth view of the **same unchanged portion**. Keep the container, food and toppings unchanged, and avoid people/private information. If weighing is practical, weigh the edible portion independently, subtract container weight, and record it separately; otherwise leave the weight unknown. Do not supply the identity/reference weight to the model during independent recognition.

Only after genuine inputs pass review: prepare the private scoped approval, verify normal authenticated local HTTPS admission, arm one case, execute and review its single response, then decide whether to arm the next. Respect rate limits instead of raising them. Any unexpected failure stops the sequence; expired authorization requires owner review, not an automatic extension. No additional allowance beyond this six-scan/12-attempt/$0.10 scope is implied.

Keep live access closed until then. No deployment, billing or mobile release action is included.
