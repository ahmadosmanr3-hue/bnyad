import { test } from 'node:test';
import assert from 'node:assert/strict';
import { allowedCatalog, buildPrompt, schemaFor, validateOutput, type Profile } from '../lib/ai/contract';
import { assertDailyPortions, DAILY_SLOTS, type DailyPortions } from '../lib/ai/daily-plan';
import { callGemini, geminiRequest, type Config } from '../lib/ai/provider';
import { RequestError } from '../lib/http';

const standard: Profile = { dailyCalories: 2000, dailyProtein: 100, dailyCarbs: 260, dailyFat: 60 };
const names = { en: 'Catalog meal', ar: 'وجبة', ku: 'ژەم' };
const instructions = { en: ['Prepare the listed ingredients.'], ar: ['حضر المكونات المذكورة.'], ku: ['پێکهاتە دیاریکراوەکان ئامادە بکە.'] };
const rawPlan = (daily: DailyPortions) => Object.fromEntries(DAILY_SLOTS.map(slot => [slot, {
  names, instructions, portions: daily[slot].map(p => ({ ...p })),
}]));
const totals = (plan: Record<string, any>) => Object.fromEntries(['calories','protein','carbs','fat'].map(k => [k,
  Object.values(plan).reduce((sum, meal) => sum + Number(meal[k]), 0),
]));
const config: Config = { model: 'gemini-3.5-flash-lite', key: 'not-a-real-key', enabled: true,
  inputRate: .3, outputRate: 2.5, budgetMicros: 0, dailyLimit: 10, minuteLimit: 3,
  inputLimit: 12000, outputLimit: 4096, timeoutMs: 25000, cacheSeconds: 21600 };

// Only catalog IDs and quantities from the two rejected FICTIONAL live trials.
const rejected: DailyPortions[] = [
  { breakfast:[{id:'p8',grams:150},{id:'g4',grams:80},{id:'o1',grams:10}],
    lunch:[{id:'p1',grams:180},{id:'g2',grams:150},{id:'v1',grams:100},{id:'o1',grams:10}],
    dinner:[{id:'p2',grams:160},{id:'g8',grams:200},{id:'o1',grams:10}],
    snacks:[{id:'d1',grams:150},{id:'f1',grams:150}] },
  { breakfast:[{id:'g3',grams:250},{id:'d1',grams:200},{id:'f2',grams:150}],
    lunch:[{id:'p1',grams:220},{id:'g1',grams:250},{id:'v1',grams:200},{id:'o1',grams:10}],
    dinner:[{id:'p2',grams:200},{id:'g9',grams:250},{id:'v12',grams:150}],
    snacks:[{id:'n1',grams:30},{id:'f1',grams:150}] },
];
test('both live failures reproduce using unchanged catalog arithmetic and validator', () => {
  const expected = [
    { calories:1893, protein:140, carbs:149, fat:78 },
    { calories:2151, protein:162, carbs:233, fat:68 },
  ];
  rejected.forEach((portions, index) => {
    const raw = rawPlan(portions);
    const meals = Object.fromEntries(DAILY_SLOTS.map(slot => [slot, validateOutput('meal', raw[slot], {}, standard)]));
    assert.deepEqual(totals(meals), expected[index]);
    assert.throws(() => validateOutput('meal-plan', raw, {}, standard), /totals do not match/);
  });
});
test('original targets are feasible without changing formulas or tolerance', () => {
  const corrected = structuredClone(rejected[0]);
  corrected.lunch.find(p => p.id === 'p1')!.grams = 100;
  corrected.lunch.find(p => p.id === 'g2')!.grams = 400;
  corrected.dinner.find(p => p.id === 'p2')!.grams = 100;
  corrected.dinner.find(p => p.id === 'g8')!.grams = 350;
  assert.doesNotThrow(() => validateOutput('meal-plan', rawPlan(corrected), {}, standard));
});

const profiles: Record<string, Profile> = {
  standard,
  smaller: { dailyCalories:1500, dailyProtein:75, dailyCarbs:190, dailyFat:50 },
  larger: { dailyCalories:2800, dailyProtein:150, dailyCarbs:350, dailyFat:80 },
  default: { dailyCalories:2200, dailyProtein:120, dailyCarbs:250, dailyFat:70 },
  vegan: { dailyCalories:2000, dailyProtein:90, dailyCarbs:270, dailyFat:65, dietaryPattern:'vegan' },
  vegetarian: { dailyCalories:1900, dailyProtein:90, dailyCarbs:250, dailyFat:60, dietaryPattern:'vegetarian' },
  pescatarian: { ...standard, dietaryPattern:'pescatarian' },
  halal: { ...standard, dietaryPattern:'halal' },
  kosher: { ...standard, dietaryPattern:'kosher' },
  allergies: { ...standard, allergies:['milk','egg','gluten','peanuts','treeNuts'] },
  lowCarb: { dailyCalories:1800, dailyProtein:110, dailyCarbs:110, dailyFat:100, dietaryPattern:'lowCarb' },
  keto: { dailyCalories:1800, dailyProtein:110, dailyCarbs:40, dailyFat:130, dietaryPattern:'keto' },
  pregnancy: { ...standard, pregnancyStatus:'pregnant' },
  dislikes: { ...standard, dislikedFoods:['chicken','fishDislike','eggsDislike','dairyDislike','olives','onions'] },
};
for (const [name, profile] of Object.entries(profiles)) {
  test(`daily portions meet every existing validator for fictional ${name}`, () => {
    const before = JSON.stringify(profile), prompt = JSON.parse(buildPrompt('meal-plan', {}, profile));
    const daily = prompt.dailyMealPortions as DailyPortions;
    assert.deepEqual(Object.keys(daily), [...DAILY_SLOTS]);
    assert.equal(JSON.stringify(profile), before);
    assert.deepEqual(JSON.parse(buildPrompt('meal-plan', {}, profile)).dailyMealPortions, daily);
    const allowed = new Set(allowedCatalog(profile).map(food => food.external_id));
    for (const slot of DAILY_SLOTS) for (const portion of daily[slot]) {
      assert.ok(allowed.has(portion.id)); assert.ok(Number.isInteger(portion.grams));
      assert.ok(portion.grams >= 1 && portion.grams <= 1000);
    }
    const result = validateOutput('meal-plan', rawPlan(daily), {}, profile);
    for (const slot of DAILY_SLOTS) {
      assert.equal(result[slot].estimated, true); assert.equal(result[slot].confirmation_required, true);
      for (const lang of ['en','ar','ku']) assert.ok(result[slot].names[lang]);
    }
    if (profile.dietaryPattern === 'keto') assert.ok(totals(result).carbs <= 50);
    if (profile.dietaryPattern === 'lowCarb') assert.ok(totals(result).carbs <= 130);
  });
}
test('invalid/inconsistent targets and unsupported allergies fail before any Google call', async () => {
  let calls = 0;
  const transport = (async () => { calls++; return new Response('{}'); }) as typeof fetch;
  for (const profile of [
    { ...standard, dailyProtein:Infinity }, { ...standard, dailyFat:-1 },
    { ...standard, dailyProtein:500, dailyCarbs:500, dailyFat:300 },
    { ...standard, allergies:['unknown'] },
  ]) {
    await assert.rejects(async () => callGemini('meal-plan', buildPrompt('meal-plan', {}, profile), {}, config, transport));
  }
  assert.equal(calls, 0);
});
test('offline sweep validates 42 consistent fictional targets across six dietary patterns', () => {
  for (const calories of [1400,1600,1800,2000,2200,2500,2800]) {
    for (const diet of ['omnivore','vegan','vegetarian','pescatarian','halal','kosher']) {
      const p: Profile = { dailyCalories:calories, dailyProtein:Math.round(calories * .2 / 4),
        dailyCarbs:Math.round(calories * .5 / 4), dailyFat:Math.round(calories * .3 / 9), dietaryPattern:diet };
      const daily = JSON.parse(buildPrompt('meal-plan', {}, p)).dailyMealPortions;
      assert.doesNotThrow(() => validateOutput('meal-plan', rawPlan(daily), {}, p));
    }
  }
});
test('structured daily response constrains exact IDs and integer quantities in all four slots', () => {
  const prompt = buildPrompt('meal-plan', {}, standard), daily = JSON.parse(prompt).dailyMealPortions as DailyPortions;
  const schema = geminiRequest('meal-plan', prompt, {}, config).generationConfig.responseJsonSchema as any;
  assert.deepEqual(schema, schemaFor('meal-plan', daily));
  for (const slot of DAILY_SLOTS) {
    const portions: any = (schema as any).properties[slot].properties.portions;
    assert.equal(portions.minItems, daily[slot].length); assert.equal(portions.maxItems, daily[slot].length);
    daily[slot].forEach((p, i) => {
      assert.deepEqual(portions.prefixItems[i].properties.id.enum, [p.id]);
      assert.deepEqual(portions.prefixItems[i].properties.grams.enum, [p.grams]);
    });
  }
  assert.throws(() => geminiRequest('meal-plan', 'fixture', {}, config), RequestError);
});
test('provider is called once, then exact portions and full multilingual output are validated', async () => {
  const prompt = buildPrompt('meal-plan', {}, standard), daily = JSON.parse(prompt).dailyMealPortions;
  const raw = rawPlan(daily); let calls = 0;
  const transport = (async () => Response.json(++calls === 1 ? { totalTokens:100 } : {
    usageMetadata:{promptTokenCount:100,totalTokenCount:300},
    candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify(raw)}]}}],
  })) as typeof fetch;
  const result = await callGemini('meal-plan', prompt, {}, config, transport);
  assert.equal(calls, 2);
  assert.doesNotThrow(() => validateOutput('meal-plan', result.result, {}, standard));
});
test('schema-ignoring output cannot substitute, duplicate or rescale server portions', async () => {
  const prompt = buildPrompt('meal-plan', {}, standard), daily = JSON.parse(prompt).dailyMealPortions;
  for (const mutation of ['rescale','substitute','duplicate','omit']) {
    const raw = rawPlan(daily);
    if (mutation === 'rescale') raw.lunch.portions[0].grams++;
    if (mutation === 'substitute') raw.lunch.portions[0].id = 'g1';
    if (mutation === 'duplicate') raw.lunch.portions[1] = { ...raw.lunch.portions[0] };
    if (mutation === 'omit') raw.dinner.portions.pop();
    assert.throws(() => assertDailyPortions(raw, daily));
    let calls = 0;
    const transport = (async () => Response.json(++calls === 1 ? { totalTokens:100 } : {
      usageMetadata:{promptTokenCount:100,totalTokenCount:300},
      candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify(raw)}]}}],
    })) as typeof fetch;
    await assert.rejects(callGemini('meal-plan', prompt, {}, config, transport));
    assert.equal(calls, 2); // Not even one automatic retry.
  }
});
test('exact portions do not bypass allergy, hidden ingredients or language validation', () => {
  const p = profiles.allergies, daily = JSON.parse(buildPrompt('meal-plan', {}, p)).dailyMealPortions;
  const raw = rawPlan(daily);
  raw.lunch = { ...raw.lunch, instructions:{ ...instructions, en:['Add peanut butter.'] } };
  assert.throws(() => validateOutput('meal-plan', raw, {}, p));
  const englishCopy = rawPlan(daily);
  englishCopy.dinner = { ...englishCopy.dinner, names:{ ...names, ku:'English only' } };
  assert.throws(() => validateOutput('meal-plan', englishCopy, {}, p));
});
