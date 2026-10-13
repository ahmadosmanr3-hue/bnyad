import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { numberValue, textValue } from '@/lib/validation';
import { parseDate, todayDate, userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

function logToJson(log: {
  id: number;
  externalFoodId: string | null;
  name: string;
  amount: number;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  micros: unknown;
  mealType: string | null;
  loggedAt: Date;
  consumedAt: Date | null;
}) {
  return {
    id: log.id,
    external_food_id: log.externalFoodId,
    name: log.name,
    amount: log.amount,
    calories: log.calories,
    protein: log.protein,
    carbs: log.carbs,
    fat: log.fat,
    micros: log.micros ?? {},
    meal_type: log.mealType,
    logged_at: log.loggedAt.toISOString().slice(0, 10),
    consumed_at: log.consumedAt?.toISOString() ?? null,
  };
}

export function OPTIONS() {
  return options();
}

async function handleGET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const { searchParams } = new URL(req.url);
  const date = searchParams.get('date') ?? todayDate();

  const logs = await prisma.dailyLog.findMany({
    where: { userId: user.id, loggedAt: parseDate(date) },
    orderBy: [{ consumedAt: 'desc' }, { id: 'desc' }],
  });

  return json({ data: logs.map(logToJson) });
}

async function handlePOST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<Record<string, unknown>>(req);
  const name = textValue(body.name, 'name', 200, true);
  if (!name) return error('Name is required.', 422);

  const log = await prisma.dailyLog.create({
    data: {
      userId: user.id,
      externalFoodId: body.external_food_id?.toString() ?? null,
      name,
      amount: numberValue(body.amount ?? 0, 'amount', 0, 100000),
      calories: numberValue(body.calories ?? 0, 'calories', 0, 100000),
      protein: numberValue(body.protein ?? 0, 'protein', 0, 100000),
      carbs: numberValue(body.carbs ?? 0, 'carbs', 0, 100000),
      fat: numberValue(body.fat ?? 0, 'fat', 0, 100000),
      micros: body.micros ?? undefined,
      mealType: body.meal_type?.toString() ?? null,
      loggedAt: parseDate(body.logged_at?.toString()),
      consumedAt: body.consumed_at ? new Date(String(body.consumed_at)) : new Date(),
    },
  });

  return json({ data: logToJson(log) }, 201);
}

export const GET = safeRoute(handleGET);
export const POST = safeRoute(handlePOST);
