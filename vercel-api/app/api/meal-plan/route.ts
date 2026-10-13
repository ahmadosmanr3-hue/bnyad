import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { numberValue, textValue } from '@/lib/validation';
import { RequestError } from '@/lib/http';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

function itemToMeal(item: {
  slot: string;
  name: string;
  names: unknown;
  ingredients: unknown;
  instructions: unknown;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  micros: unknown;
}) {
  return {
    name: item.name,
    names: item.names ?? undefined,
    ingredients: item.ingredients ?? [],
    instructions: item.instructions ?? [],
    calories: item.calories,
    protein: item.protein,
    carbs: item.carbs,
    fat: item.fat,
    micros: item.micros ?? {},
  };
}

async function handleGET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const plan = await prisma.mealPlan.findUnique({
    where: { userId: user.id },
    include: { items: true },
  });

  if (!plan) return json({ data: null });

  const planMap: Record<string, unknown> = {};
  for (const item of plan.items) {
    planMap[item.slot] = itemToMeal(item);
  }

  return json({
    data: {
      id: plan.id,
      generated_at: plan.generatedAt?.toISOString() ?? null,
      plan: planMap,
    },
  });
}

async function handlePUT(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<{ plan?: Record<string, Record<string, unknown>> }>(req);
  const planBody = body.plan ?? {};
  if (typeof planBody !== 'object' || Array.isArray(planBody) || Object.keys(planBody).length > 10) {
    throw new RequestError('Invalid meal plan.');
  }
  const items = Object.entries(planBody).map(([slot, meal]) => {
      if (!meal || typeof meal !== 'object' || Array.isArray(meal)) throw new RequestError('Invalid meal.');
      return {
        slot,
        name: textValue(meal.name ?? '', 'meal name', 200),
        names: (meal.names as object) ?? undefined,
        ingredients: (meal.ingredients as object) ?? undefined,
        instructions: (meal.instructions as object) ?? undefined,
        calories: numberValue(meal.calories ?? 0, 'calories', 0, 100000, true),
        protein: numberValue(meal.protein ?? 0, 'protein', 0, 100000, true),
        carbs: numberValue(meal.carbs ?? 0, 'carbs', 0, 100000, true),
        fat: numberValue(meal.fat ?? 0, 'fat', 0, 100000, true),
        micros: (meal.micros as object) ?? undefined,
      };
  });
  // Replace atomically. An invalid item or interrupted request cannot erase
  // the previous plan. Nested writes roll back together.
  const saved = await prisma.mealPlan.upsert({
    where: { userId: user.id },
    create: { userId: user.id, generatedAt: new Date(), items: { create: items } },
    update: { generatedAt: new Date(), items: { deleteMany: {}, create: items } },
    include: { items: true },
  });

  const planMap: Record<string, unknown> = {};
  for (const item of saved!.items) {
    planMap[item.slot] = itemToMeal(item);
  }

  return json({
    data: {
      id: saved!.id,
      generated_at: saved!.generatedAt?.toISOString() ?? null,
      plan: planMap,
    },
  });
}

async function handleDELETE(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  await prisma.mealPlan.deleteMany({ where: { userId: user.id } });
  return json({ message: 'Meal plan cleared.' });
}

export const GET = safeRoute(handleGET);
export const PUT = safeRoute(handlePUT);
export const DELETE = safeRoute(handleDELETE);
