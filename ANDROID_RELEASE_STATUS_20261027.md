# Android release verified — 27 October 2026

Read-only verification in the owner's signed-in Google Play Console:

- Existing BNYAD listing, app ID `4973400403852746672`.
- Submission **9**, containing four submitted changes, shows **Published**.
- Production release: **version code 17, version 1.0.2**.
- Console-displayed publication time: **27 October 2026, 3:17 PM**.
- Console app title: **BNYAD: Calorie & Macro Tracker**.

[Google Play submission details](https://play.google.com/console/u/0/developers/5362702642120308085/app/4973400403852746672/publishing/submission-activity/9/details)

No new release, rollout, signing, device exclusion, subscription price or listing edit was performed during this verification. Public search indexing, every country/device's update propagation and the installation on individual Android phones were not independently checked. The public listing could not be fetched with the web-search tool, so the authenticated publisher console is the source for this status.

Both this Android release and [Apple 1.0.2/build 16](APPLE_RELEASE_STATUS_20261027.md) are now verified as published/available through their respective checks. [Server AI and monthly cap behavior](SERVER_AI_AND_FINANCE_HANDOFF.md) is controlled separately by the backend; no additional mobile binary was needed for AI activation. Static paused-AI store copy still needs a separate metadata correction.

## Later update: 1.0.3 (18)

On 27 October, the owner-authorized client clarification and English listing correction were submitted together. Google Play Publishing overview shows **Changes in review**, with production **18 (1.0.3)** / Start full rollout and the English default listing full-description change. Google's automated quick checks subsequently completed; the console explicitly says the changes are now in review. This is submission evidence, not approval or publication of 1.0.3. The existing published 17 (1.0.2) remains the last verified public Android release.

See [candidate verification](RELEASE_1.0.3_18.md). Source fix: `490c8d4cfc03612ac3327a659d379b626ac2648c`; artifact-verification commit: `4aa27d61798779dd222d2ccc55645fa8d30a610d`. No Samsung was connected for a new physical build-18 smoke check; automated tests and signed-bundle validation passed.
