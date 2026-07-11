import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import type { User, UserProfile, Subscription } from '@prisma/client';
import { prisma } from './db';

export const DEMO_OTP = '123456';

export function isProduction() {
  return process.env.APP_ENV === 'production';
}

export async function hashPassword(password: string) {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hash: string) {
  return bcrypt.compare(password, hash);
}

export async function hashOtp(code: string) {
  return bcrypt.hash(code, 10);
}

export async function verifyOtp(code: string, hash: string) {
  return bcrypt.compare(code, hash);
}

export function newToken() {
  return crypto.randomBytes(40).toString('hex');
}

export async function createSession(userId: number) {
  const token = newToken();
  await prisma.apiToken.create({ data: { userId, token } });
  return token;
}

export async function userFromAuthHeader(authHeader: string | null) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice(7).trim();
  if (!token) return null;
  const row = await prisma.apiToken.findUnique({
    where: { token },
    include: { user: { include: { profile: true, subscriptions: true } } },
  });
  return row?.user ?? null;
}

export function profileToJson(p: UserProfile) {
  return {
    display_name: p.displayName,
    weight: p.weight,
    height: p.height,
    age: p.age,
    gender: p.gender,
    activity_level: p.activityLevel,
    goal: p.goal,
    sicknesses: (p.sicknesses as string[]) ?? [],
    allergies: (p.allergies as string[]) ?? [],
    disabilities: (p.disabilities as string[]) ?? [],
    daily_calories: p.dailyCalories,
    daily_carbs: p.dailyCarbs,
    daily_protein: p.dailyProtein,
    daily_fat: p.dailyFat,
    language: p.language,
    theme: p.theme,
    onboarded: p.onboarded,
    target_weight: p.targetWeight,
    pace: p.pace,
    body_fat_pct: p.bodyFatPct,
    pregnancy_status: p.pregnancyStatus,
    dietary_pattern: p.dietaryPattern,
    disliked_foods: (p.dislikedFoods as string[]) ?? [],
    cuisine_preference: p.cuisinePreference,
    meals_per_day: p.mealsPerDay,
    fasting_window: p.fastingWindow,
    sleep_hours: p.sleepHours,
    stress_level: p.stressLevel,
    water_target_ml: p.waterTargetMl,
    medications: p.medications,
    workout_days_per_week: p.workoutDaysPerWeek,
    workout_type: p.workoutType,
    cooking_skill: p.cookingSkill,
    cooking_time: p.cookingTime,
  };
}

export function userToJson(user: User & { profile: UserProfile | null; subscriptions?: Subscription[] | null }) {
  const now = new Date();
  const activeSub = user.subscriptions
    ? user.subscriptions.find((sub) => sub.active && new Date(sub.expiresAt) > now)
    : null;

  return {
    id: user.id,
    name: user.name,
    phone: user.phone,
    email: user.email,
    profile: user.profile ? profileToJson(user.profile) : null,
    subscription: {
      isPremium: !!activeSub,
      plan: activeSub?.plan ?? null,
      expiresAt: activeSub?.expiresAt ? activeSub.expiresAt.toISOString() : null,
      active: !!activeSub,
    },
  };
}

const profileFieldMap: Record<string, string> = {
  display_name: 'displayName',
  activity_level: 'activityLevel',
  daily_calories: 'dailyCalories',
  daily_carbs: 'dailyCarbs',
  daily_protein: 'dailyProtein',
  daily_fat: 'dailyFat',
  target_weight: 'targetWeight',
  body_fat_pct: 'bodyFatPct',
  pregnancy_status: 'pregnancyStatus',
  dietary_pattern: 'dietaryPattern',
  disliked_foods: 'dislikedFoods',
  cuisine_preference: 'cuisinePreference',
  meals_per_day: 'mealsPerDay',
  fasting_window: 'fastingWindow',
  sleep_hours: 'sleepHours',
  stress_level: 'stressLevel',
  water_target_ml: 'waterTargetMl',
  workout_days_per_week: 'workoutDaysPerWeek',
  workout_type: 'workoutType',
  cooking_skill: 'cookingSkill',
  cooking_time: 'cookingTime',
};

export function mapProfileUpdate(body: Record<string, unknown>) {
  const data: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(body)) {
    const mapped = profileFieldMap[key] ?? key;
    data[mapped] = value;
  }
  return data;
}

export function todayDate() {
  return new Date().toISOString().slice(0, 10);
}

export function parseDate(value: string | null | undefined) {
  const d = value ?? todayDate();
  return new Date(`${d}T12:00:00.000Z`);
}
