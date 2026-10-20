import { RequestError } from '../http';

export const DAILY_SLOTS = ['breakfast', 'lunch', 'dinner', 'snacks'] as const;
export type DailySlot = typeof DAILY_SLOTS[number];
export type Portion = { id: string; grams: number };
export type DailyPortions = Record<DailySlot, Portion[]>;
type Targets = { calories: number; protein: number; carbs: number; fat: number };
type Food = { external_id: string; serving_size: number; calories: number; protein: number; carbs: number; fats: number };
type Variable = { slot: DailySlot; food: Food; grams: number; min: number; max: number };
const nutrients = ['calories', 'protein', 'carbs', 'fat'] as const;
const invalid = () => { throw new RequestError('A valid daily plan could not be prepared for these targets and restrictions. Review your saved preferences.', 422); };

/** Deterministic portion planning, not a new nutrition formula. Candidates use
 * only the caller's already-filtered catalog. The caller MUST approve them with
 * the unchanged full output validator before they can be sent to Gemini.
 * Nothing is written back to the profile and no invalid model output is scaled.
 */
export function prepareDailyPortions(allowed: Food[], targets: Targets, accepts: (portions: DailyPortions) => boolean): DailyPortions {
  if (nutrients.some(k => !Number.isFinite(targets[k]) || targets[k] < 0) || targets.calories <= 0) return invalid();
  const byId = new Map(allowed.map(food => [food.external_id, food]));
  const variables: Variable[] = [];
  const scale = Math.max(.5, Math.min(1.8, targets.calories / 2000));
  const veryLowCarb = targets.carbs <= 50;
  const add = (slot: DailySlot, ids: string[], seed: number, min: number, max: number) => {
    const food = ids.map(id => byId.get(id)).find((f): f is Food => !!f);
    if (food && !variables.some(v => v.slot === slot && v.food.external_id === food.external_id)) {
      variables.push({ slot, food, grams: Math.max(min, Math.min(max, seed * scale)), min, max });
    }
  };
  // Modest, bounded ingredient roles give Gemini different meal compositions,
  // while leaving titles and cooking explanations to its trilingual response.
  add('breakfast', veryLowCarb ? ['v3','v2','v10'] : ['g3','g4','g2','g9'], 200, 40, 450);
  add('breakfast', ['d1','p8','p18','l3','l1'], 100, 25, 250);
  if (!veryLowCarb) add('breakfast', ['f2','f1','f3'], 100, 30, 250);
  add('breakfast', ['n1','n2','o1'], 15, 2, 35);
  add('lunch', veryLowCarb ? ['v10','v6','v12'] : ['g2','g1','g7','g9'], 250, 40, 600);
  add('lunch', ['p1','p18','l3','l1','p2','p8'], 100, 25, 300);
  add('lunch', ['v1','v3','v2','v5'], 100, 40, 250);
  add('lunch', ['o1','n1','n2'], 10, 1, 25);
  add('dinner', veryLowCarb ? ['v6','v10','v12'] : ['g9','g8','g2','g1'], 250, 40, 600);
  add('dinner', ['p2','p1','p18','l3','l1','p8'], 100, 25, 300);
  add('dinner', ['v2','v10','v3','v1'], 100, 40, 250);
  add('dinner', ['o1','n1','n2'], 10, 1, 25);
  if (!veryLowCarb) add('snacks', ['f1','f2','f3'], 150, 30, 250);
  add('snacks', ['n2','n1','d1','p18','l1'], 20, 5, 100);
  if (DAILY_SLOTS.some(slot => !variables.some(v => v.slot === slot))) return invalid();
  const vector = (v: Variable) => [v.food.calories, v.food.protein, v.food.carbs, v.food.fats]
    .map((value, i) => value / v.food.serving_size / Math.max(targets[nutrients[i]], 1));
  const columns = variables.map(vector);
  if (columns.some(col => col.some(x => !Number.isFinite(x) || x < 0))) return invalid();
  const asPlan = (): DailyPortions => Object.fromEntries(DAILY_SLOTS.map(slot => [slot,
    variables.filter(v => v.slot === slot).map(v => ({ id: v.food.external_id, grams: Math.round(v.grams) })),
  ])) as DailyPortions;
  // Coordinate descent is bounded local arithmetic, never an API retry loop.
  // Minimize relative errors in all four nutrients, not just total calories.
  for (let iteration = 0; iteration < 400; iteration++) {
    const residual = nutrients.map((k, i) => columns.reduce((s, col, j) => s + col[i] * variables[j].grams, 0)
      - (targets[k] === 0 ? 0 : 1));
    let movement = 0;
    for (let j = 0; j < variables.length; j++) {
      const v = variables[j], col = columns[j], norm = col.reduce((s, x) => s + x * x, 0);
      if (norm === 0) continue;
      const step = -col.reduce((s, x, i) => s + x * residual[i], 0) / norm;
      const next = Math.max(v.min, Math.min(v.max, v.grams + step)), delta = next - v.grams;
      v.grams = next; movement += Math.abs(delta);
      for (let i = 0; i < 4; i++) residual[i] += col[i] * delta;
    }
    if (iteration >= 15 && (iteration % 10 === 0 || movement < .001)) {
      const candidate = asPlan();
      if (accepts(candidate)) return candidate;
    }
    if (movement < .001) break;
  }
  return invalid(); // No guarantee of feasibility for every diet/target/catalog.
}

/** A provider ignoring the schema must not replace validated portion weights. */
export function assertDailyPortions(raw: unknown, expected: DailyPortions) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return invalid();
  for (const slot of DAILY_SLOTS) {
    const portions = (raw as Record<string, any>)[slot]?.portions;
    if (!Array.isArray(portions) || portions.length !== expected[slot].length) return invalid();
    const seen = new Set<string>();
    for (const item of portions) {
      if (!item || seen.has(item.id) || !expected[slot].some(p => p.id === item.id && p.grams === item.grams)) return invalid();
      seen.add(item.id);
    }
  }
}
