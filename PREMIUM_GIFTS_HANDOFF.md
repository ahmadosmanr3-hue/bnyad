# Premium gifts — mobile handoff

New release candidate: 1.0.2 (16), preserving existing production and development
identifiers, HealthKit/Health Connect and original UI. Build 15 remains the
installed internal TestFlight build; this source is not yet installed there.

Backend source and deployment instructions are in the official bnyad-backend repo,
`vercel-api/PREMIUM_GIFT_CAMPAIGNS.md`. Do not deploy the older backend mirror from
this Flutter repository. The backend adds five additive tables and the default-off
`PREMIUM_GIFTS_ENABLED` switch. No build or deployment creates a campaign.

The mobile app reads server promotional entitlements through the normal
authenticated subscription endpoint, refreshes on resume/foreground polling/push,
and shows localized gift details separately from store-managed purchases. Gift
dates can move after paid renewals; lifetime users bank credit. Promotional access
cannot be issued or extended by the client. Campaign alerts are not replayed when
the inbox refreshes, and taps open gift details. AI remains disabled independently.

Flutter analysis and 410 tests pass. Tests include 20 gift metadata/refresh/layout
cases and 12 purchase-verification cases. EN/AR/Sorani gift screens are checked at
320/390/768 widths in light and dark with the bundled fonts. Images in
`docs/evidence/premium-gifts/` are fictional widget fixtures, not phone screenshots.

Backend tests include 10,000 real local PostgreSQL fixture grants and a native
local durable-workflow/browser confirmation flow with five fictional recipients.
No real global grant, production broadcast, Google request, billing activation or
production subscription change was made for these tests.

Remaining gates: backend migration/configuration/deployment verification, physical
device gift refresh/navigation and new signed builds. Previously supervised
TestFlight purchase, Restore and restart persistence succeeded with a trusted
server `store_verified` record. Existing admin grants were preserved. Public store
submission stays subject to the main production-repair checklist and owner review.
