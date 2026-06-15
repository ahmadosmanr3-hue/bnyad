import { prisma } from '@/lib/db';
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

export async function GET(req: Request) {
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

export async function PUT(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<{ plan?: Record<string, Record<string, unknown>> }>(req);
  const planBody = body.plan ?? {};

  const plan = await prisma.mealPlan.upsert({
    where: { userId: user.id },
    create: { userId: user.id, generatedAt: new Date() },
    update: { generatedAt: new Date() },
  });

  await prisma.mealPlanItem.deleteMany({ where: { mealPlanId: plan.id } });

  for (const [slot, meal] of Object.entries(planBody)) {
    await prisma.mealPlanItem.create({
      data: {
        mealPlanId: plan.id,
        slot,
        name: String(meal.name ?? ''),
        names: (meal.names as object) ?? undefined,
        ingredients: (meal.ingredients as object) ?? undefined,
        instructions: (meal.instructions as object) ?? undefined,
        calories: Number(meal.calories ?? 0),
        protein: Number(meal.protein ?? 0),
        carbs: Number(meal.carbs ?? 0),
        fat: Number(meal.fat ?? 0),
        micros: (meal.micros as object) ?? undefined,
      },
    });
  }

  const saved = await prisma.mealPlan.findUnique({
    where: { id: plan.id },
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

export async function DELETE(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  await prisma.mealPlan.deleteMany({ where: { userId: user.id } });
  return json({ message: 'Meal plan cleared.' });
}
