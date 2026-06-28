import { prisma } from '@/lib/db';
import { isAdminAuthed } from '@/lib/admin';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

type Params = { params: Promise<{ id: string }> };

/**
 * Resets a user's data so they start fresh: removes all food logs, water,
 * weight history, and the meal plan, and forces onboarding again by clearing
 * the profile back to defaults (keeps the display name + language).
 * Login credentials and subscriptions are kept.
 */
export async function POST(req: Request, { params }: Params) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const { id } = await params;
  const userId = Number(id);
  if (!Number.isInteger(userId)) return error('Invalid id.', 422);

  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { profile: true },
  });
  if (!user) return error('User not found.', 404);

  await prisma.$transaction([
    prisma.dailyLog.deleteMany({ where: { userId } }),
    prisma.waterLog.deleteMany({ where: { userId } }),
    prisma.weightEntry.deleteMany({ where: { userId } }),
    prisma.mealPlan.deleteMany({ where: { userId } }),
  ]);

  // Reset the profile to defaults but keep the name + language so the user
  // doesn't have to retype them; force onboarding to run again.
  await prisma.userProfile.upsert({
    where: { userId },
    create: {
      userId,
      displayName: user.profile?.displayName ?? '',
      language: user.profile?.language ?? 'en',
      onboarded: false,
    },
    update: {
      onboarded: false,
      weight: 70,
      height: 175,
      age: 25,
      gender: 'male',
      activityLevel: 'moderatelyActive',
      goal: 'stayHealthy',
      sicknesses: [],
      allergies: [],
      disabilities: [],
      dailyCalories: 2200,
      dailyCarbs: 250,
      dailyProtein: 120,
      dailyFat: 70,
      targetWeight: null,
      pace: 'moderate',
      bodyFatPct: null,
      pregnancyStatus: 'none',
      dietaryPattern: 'omnivore',
      dislikedFoods: [],
      cuisinePreference: 'mixed',
      mealsPerDay: 3,
      fastingWindow: 'none',
      sleepHours: null,
      stressLevel: 'medium',
      waterTargetMl: null,
      medications: null,
      workoutDaysPerWeek: 0,
      workoutType: 'none',
      cookingSkill: 'intermediate',
      cookingTime: 'under30',
    },
  });

  return json({ ok: true });
}
