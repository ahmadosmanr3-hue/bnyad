# BNYAD food import readiness — 5 November 2026

**Ready for Prompt 2 with a bounded validated subset and explicit review gates. No production writes or deployment occurred.** Research continues from the original evidence, which remains intact. This handoff does not claim the entire Juula catalog or every preparation is verified.

## Final counts and reconciliation

- 1,340 primary food/category entries, all with English, Arabic and Kurdish Sorani names. Badini excluded.
- 1,340 Arabic category observations, now all paired to the English inventory; all 27 directory lists inspected in each requested language.
- English meat recheck found 98 rows, resolving the earlier 50-versus-98 discrepancy. The 48 additional category associations were retained; they are not 48 proven unique new recipes.
- 1,133 exact name/nutrition/reference/preparation contexts after grouping 207 duplicate category associations. Raw observations and original research IDs were not deleted. This conservative grouping does not merge differently named recipes or conflicting references.
- 350 technically usable, multilingual UI-reference contexts in `JUULA_VALIDATED_CANDIDATES.json`. These are observed estimates, not independently certified regional recipes. Their source rights still need review before publication.
- 783 technical-review contexts in `JUULA_REVIEW_QUEUE.json`: missing references, unresolved list/detail differences, or nutrition-screening flags. Rights flags also apply to the technically usable group.
- **2 independently sourced additions** in `BNYAD_IMPORT_READY.json`: USDA SR Legacy Chinese-restaurant egg-drop soup (FDC 174807) and cultured sour cream (FDC 171257). These use actual USDA values, explicit 100 g references and CC0 identifiers, not substituted Juula decimal values. Clarifying localized labels need owner wording review. Neither is a certified equivalent of a local recipe.

The ready file passed the existing backend `catalogFood` validator. No importer was executed. Eight research regression tests pass; Arabic evidence audit and primary linked-evidence audit report zero issues/broken links.

## Regional coverage

Saved categories include 42 rice dishes, 14 dolma/stuffed-vegetable entries, 44 broths/stews, 50 soups, 11 bulgur/wheat dishes, 20 kubba/kibbeh/kofta entries, 104 breads/pastries, 98 meat entries, 104 chicken entries, 14 egg dishes, 78 dairy entries and 164 sweets/desserts. There are also wraps, pizza, fish, salads, fruit, vegetables, nuts, spices, coffee and juice categories. Counts include overlapping category membership.

Rice/biryani, leaf/onion/vegetable dolma and yaprax, kebabs and grilled meats, breads, regional soups/stews, breakfasts and desserts are represented. Representation is not verification of all ingredients, yields or serving weights.

The two Sorani plum pairings were resolved by comparing saved English/Sorani source images and labels: dark Black Plum versus green Greengage, with matching displayed nutrition. This establishes source-label mapping, not a botanical certification. Images stay internal and must not ship in BNYAD.

## Macro-energy review and inaccessible details

`MACRO_ENERGY_REVIEW.json` reviews all 34 original flags. Eighteen have primary USDA numerical comparators reproducing declared calories/macros; generic 4/4/9 calculations do not account for fiber and food-specific energy factors. That corroboration is not proof of an identical Juula recipe or its licensing. Sixteen remain unexplained, including Penne Arrabbiata and mixed-spice preparations. No calories or macros were altered to force agreement. Star anise versus anise seed must not be collapsed simply because nutrition is equal.

Vegetable Fried Rice and Shamburak retain their separate list/detail macro discrepancies. An accessible detail with different nutrition must remain a separate preparation observation; its calories must never be combined with the list's different macros.

All unavailable/pending records were triaged by recorded evidence and reference status. **They were not all individually retried.** Four bounded priority revisits—Egg and Tomato, Penne Arrabbiata, Fruit Yogurt and Fresh Apple Juice—still failed to produce stable complete details. See `cleanup-detail-revisits.json`. Earlier unavailable details remain 567 category observations; pending details are now 292 after the meat recheck. Six additional primary-reference mismatches remain. These are coverage gaps, not proof the foods permanently lack details. The project proceeds without assigning missing bases or weights.

## Additional normal-interface checks

- Searches using Arabic `دولمة` and Sorani `کەباب` returned relevant dolma and kebab foods while the UI was English. This verifies multilingual query acceptance, not every search ranking, spelling or localized-interface combination.
- Branded queries Coca-Cola, Pepsi, Monster and Red Bull returned relevant regular/diet/zero products and some unrelated fuzzy matches. Saved results show macros; missing energy/reference volume must not be invented. Region, formulation and package sizes need product-label verification. Existing manufacturer-reviewed BNYAD drinks should take precedence over an ambiguous name match.
- Restaurants directory inspected; Mam Xasraw menu showed regional pacha, mumbar, lamb dishes and kebab. Its per-person/per-skewer menu values are not per 100 g. Menu content required a no-idle accessibility snapshot because of ongoing layout events. Restaurant recipes, complete serving weights and reuse rights remain unverified; no restaurant data is in the ready import.
- New foods section inspected: sour-cherry juice, coffee milkshake, caramel frappe and mulberry juice appeared. Only the inspected viewport is claimed; it is not an exhaustive New foods export.
- Favorites and populated recents were not newly tested in this cleanup. No Juula meal log, personal portion override or purchase was saved. Existing evidence and these specific gaps are retained for implementation testing rather than indefinite source-app research.

## Live BNYAD comparison — A, B, C

Read-only public production `GET /api/catalog` returned **940 foods, revision 2**. The response is saved as `BNYAD_LIVE_CATALOG_SNAPSHOT.json`. This comparison does not enumerate private user-created foods, favorites or meal history. Latest fetched backend catalog branch: `codex/bnyad-catalog-completion-2026-11-04`, commit `bf053c9d2099591598698680d912f864f74257a6`.

### A — Missing and ready to add

`BNYAD_IMPORT_READY.json`: the two independently sourced USDA references above, absent by source FDC ID in the public snapshot. Keep proposed stable `usda_sr_...` IDs and explicit preparation-qualified English descriptions. Do not market the Chinese-restaurant soup as a verified Kurdish soup.

`JUULA_VALIDATED_CANDIDATES.json`: 350 technically usable contexts for owner/source review, not an automatically approved production import. Names, original references, nutrition, preparation, servings, evidence, rights and validation states are retained. Resolve rights and any overlapping BNYAD identity before promoting these records.

### B — Existing entries that may be improved

`BNYAD_EXISTING_IMPROVEMENTS.json` contains two conservative exact-name-and-nutrition matches: Brown Rice (`g1`) and Rye bread (`usda_sr_172684`). Review additional observed names/aliases, category placement and food-specific servings without changing their IDs, canonical IDs or nutrition. A matching name/nutrition tuple is not proof a new portion is appropriate for every recipe.

The comparison deliberately avoids fuzzy automatic updates. More potential name/alias improvements can be proposed during Prompt 2, but require explicit identity/preparation review.

### C — Duplicates, conflicts and uncertainty

`BNYAD_CONFLICTS.json` contains 128 existing-name matches with conflicting or unverified nutrition/reference contexts. These are candidate match edges, not 128 proven distinct bad foods. Do not overwrite Maqluba, Mansaf, Tashreeb, generic dolma or other legacy recipes based on name resemblance. Keep legitimate recipes distinct and use qualified names. The 783 technical-review contexts remain separately inspectable. Duplicate category membership was grouped only on the exact documented context; portions and original associations remain traceable.

## Serving readiness

- Use explicit grams and quantities first. Chicken Bryani shows 13 g/tablespoon and 410 g/plate; these source-account weights are not universal spoon/plate definitions. Red Rice oil/no-oil preparations remain separate.
- Dry tiri: 364 kcal/100 g, 70 g piece. Softened tiri: 260 kcal/100 g, 98 g piece. Do not cross-apply weights.
- Source personal portion editor says overrides affect only that user and future logs. Label source servings as estimates; allow a user-defined measured spoon or plate, while retaining grams as the reliable fallback.
- Pizza: grams always available when the reference is established. Slices need product-specific grams/slice; whole pizza needs measured mass or a verified slices-per-pizza conversion. No universal slice size or pizza diameter-to-weight conversion.
- Drinks: mL reference, exact L-to-mL factor 1,000. Can/bottle choices require verified package volume and region/formulation. Never convert grams to mL at unit density without evidence. Lemonade's 100 mL reference and separately displayed 240 g cup do not establish a 240 mL serving.
- Ready USDA additions intentionally have no invented serving weights. Existing independently sourced BNYAD portions can be reused only for the same food/reference.

## Rights and attribution

The user reports owner Imam's verbal permission for normal-interface research and food-information reuse. That does not establish unidentified third-party rights. Each Juula candidate retains its research-only rights flag. Before promoting bulk UI-derived recipes, document owner-authored data scope or applicable provider license/attribution. Do not relabel it USDA because values resemble a database row. Keep original screenshots, logos and photographs out of shipped assets.

USDA references are independently sourced CC0 data; retain FDC identifiers, dataset edition, reference basis and attribution. Two ready additions can proceed independently of unresolved Juula records. UI implementation can also proceed without publishing review-queue data.

## Exact Prompt 2 implementation sequence

1. Freeze this research package and hash the selected manifest. Re-fetch both repositories and preserve all unrelated uncommitted work. Re-read the live public catalog revision before proposing edits.
2. Add the two ready references through the existing deterministic catalog build. Keep pending Juula records in a separate review file, never load them by default. Stage language/serving improvements as explicit per-ID patches, not blanket replacements.
3. Extend the existing importer with a genuine read-only diff/dry-run manifest before applying changes; the current `--confirmed-target` path performs a transaction and must not be mistaken for a dry run. Test against an isolated database. Assert idempotency, stable external/canonical IDs, duplicate handling and rollback. Never delete user-created foods, favorites or historical meal snapshots; category changes must not rewrite nutrition history.
4. Preserve the existing category tree and add narrowly scoped regional browsing/filter labels. Give foods multiple browse associations without duplicating canonical identities. Keep recipe, raw/cooked and oil variants distinct.
5. Improve only food browsing and meal logging: text-only rows without thumbnails, readable name and reference basis, compact calories/macros, generous favorite touch targets, accessible selected/loading/error states. Preserve the rest of BNYAD's design, dashboard and navigation.
6. Normalize search consistently in Flutter and backend: Unicode normalization, Arabic/Sorani letter variants, diacritics/tatweel, spaces and digit forms. Preserve original display strings. Add only verified aliases; test `دولمة`, `یاپراخ`, `کەباب`, biryani variants and all three languages. Rank exact and prefix matches before loose matches. Do not merge distinct food identities as a search shortcut.
7. Favorites must use the existing stable food/canonical-key rules and authenticated per-user endpoints. Prevent double taps/races; reconcile optimistic UI on failure. Test repeated toggles, food details/list synchronization, restart and pagination; no mutation during catalog reconciliation.
8. Implement reference-aware serving controls for rice/biryani, pizza and drinks using the rules above. Reuse existing calculations; convert once from a known reference, validate positive finite quantities, and retain source/estimated labels. Support numeric input in all languages without changing stored historical quantities.
9. Optional second AI photo: extend existing Flutter/backend contracts with an optional container-depth image, strict maximum two images and a combined byte limit. Explain optional Google sharing, preserve consent, authentication, Premium, quotas and budgets. Do not infer exact depth/grams from photos alone; request user confirmation. Mock first; no new live Gemini tests or production enablement are authorized by this research task.
10. Test narrow phones and tablets, English LTR plus Sorani/Arabic RTL, large text, keyboard, empty/loading/errors, favorite persistence and responsive logging dialogs. Keep nutrition and subscription rules unchanged. Run relevant Flutter and backend tests and analysis, catalog validator, deterministic-build checks and isolated import tests.
11. Present the selected-data diff, UI preview and test results before any production database action. Source commits belong in the official app/backend repositories during implementation. Production migrations/imports, deployment and store publication are separate actions; none occurred here.

## Remaining limits and completion

Unresolved source details, independent recipe nutrition, full restaurant coverage, exhaustive branded search, localized-interface search permutations and populated favorites/recents remain documented work—not blockers for the independent subset and bounded UI implementation. No false whole-catalog completeness claim is made.

**The research package is ready for Prompt 2.**
