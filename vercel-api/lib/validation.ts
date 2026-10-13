import { RequestError } from './http';

export function numberValue(value: unknown, name: string, min: number, max: number, integer = false): number {
  if ((typeof value !== 'number' && typeof value !== 'string') || value === '') throw new RequestError(`${name} must be a number.`);
  const n = Number(value);
  if (!Number.isFinite(n) || n < min || n > max || (integer && !Number.isInteger(n))) {
    throw new RequestError(`${name} is outside the allowed range.`);
  }
  return n;
}

export function dateValue(value: unknown, fallback: string): Date {
  const s = value ?? fallback;
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) throw new RequestError('Invalid date. Use YYYY-MM-DD.');
  const date = new Date(`${s}T12:00:00.000Z`);
  if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== s) throw new RequestError('Invalid date.');
  return date;
}

export function textValue(value: unknown, name: string, max = 200, required = false): string {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) throw new RequestError(`Invalid ${name}.`);
  return value.trim();
}

const numeric: Record<string, [number, number, boolean?]> = {
  weight: [0, 600], height: [0, 300], age: [0, 120, true],
  dailyCalories: [0, 20000, true], dailyCarbs: [0, 5000, true],
  dailyProtein: [0, 5000, true], dailyFat: [0, 5000, true],
  targetWeight: [0, 600], bodyFatPct: [0, 100], mealsPerDay: [1, 10, true],
  sleepHours: [0, 24], waterTargetMl: [0, 20000, true], workoutDaysPerWeek: [0, 7, true],
};
const strings = new Set(['displayName', 'gender', 'activityLevel', 'goal', 'language', 'theme', 'pace',
  'pregnancyStatus', 'dietaryPattern', 'cuisinePreference', 'fastingWindow', 'stressLevel',
  'medications', 'workoutType', 'cookingSkill', 'cookingTime']);
const arrays = new Set(['sicknesses', 'allergies', 'disabilities', 'dislikedFoods']);
const nullable = new Set(['displayName', 'targetWeight', 'bodyFatPct', 'sleepHours', 'waterTargetMl', 'medications']);

export function validateProfile(data: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(data)) {
    // Historical clients sent this local-only field. Never pass it to Prisma.
    if (key === 'dailyMicroGoals' || key === 'daily_micro_goals') continue;
    if (nullable.has(key) && value === null) { result[key] = null; continue; }
    if (numeric[key]) {
      const [min, max, integer] = numeric[key];
      result[key] = numberValue(value, key, min, max, integer);
    } else if (strings.has(key)) {
      result[key] = textValue(value, key, key === 'medications' ? 2000 : 120);
      if (key === 'language') {
        if (!['en', 'ar', 'ku', 'ckb'].includes(result[key] as string)) throw new RequestError('Invalid language.');
        if (value === 'ckb') result[key] = 'ku';
      }
      if (key === 'theme' && !['light', 'dark'].includes(result[key] as string)) throw new RequestError('Invalid theme.');
    } else if (arrays.has(key)) {
      if (!Array.isArray(value) || value.length > 100) throw new RequestError(`Invalid ${key}.`);
      result[key] = value.map((v) => textValue(v, key, 120));
    } else if (key === 'onboarded' && typeof value === 'boolean') {
      result[key] = value;
    } else {
      // Prevent primary key changes, reassignment and nested relation writes.
      throw new RequestError(`Unsupported profile field: ${key}.`);
    }
  }
  return result;
}
