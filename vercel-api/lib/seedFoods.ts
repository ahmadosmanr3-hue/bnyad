import fs from 'fs';
import path from 'path';
import { prisma } from './db';

type FoodRow = {
  external_id?: string;
  category?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fats?: number;
  fat?: number;
  serving_size?: number;
  serving_unit?: string;
  micros?: Record<string, number>;
  names?: Record<string, string>;
  descriptions?: Record<string, string>;
};

export async function seedFoods() {
  const jsonPath = path.join(process.cwd(), 'data', 'food_items.json');
  if (!fs.existsSync(jsonPath)) {
    return { seeded: 0, message: 'No data/food_items.json found.' };
  }

  const items = JSON.parse(fs.readFileSync(jsonPath, 'utf8')) as FoodRow[];
  let seeded = 0;

  for (const row of items) {
    if (!row.external_id) continue;

    const food = await prisma.foodItem.upsert({
      where: { externalId: row.external_id },
      create: {
        externalId: row.external_id,
        category: row.category ?? null,
        calories: row.calories ?? 0,
        protein: row.protein ?? 0,
        carbs: row.carbs ?? 0,
        fats: row.fats ?? row.fat ?? 0,
        servingSize: row.serving_size ?? 100,
        servingUnit: row.serving_unit ?? 'g',
        micros: row.micros ?? undefined,
      },
      update: {
        category: row.category ?? null,
        calories: row.calories ?? 0,
        protein: row.protein ?? 0,
        carbs: row.carbs ?? 0,
        fats: row.fats ?? row.fat ?? 0,
        servingSize: row.serving_size ?? 100,
        servingUnit: row.serving_unit ?? 'g',
        micros: row.micros ?? undefined,
      },
    });

    for (const [locale, name] of Object.entries(row.names ?? {})) {
      if (!name) continue;
      await prisma.foodItemTranslation.upsert({
        where: { foodItemId_locale: { foodItemId: food.id, locale } },
        create: {
          foodItemId: food.id,
          locale,
          name,
          description: row.descriptions?.[locale] ?? null,
        },
        update: { name, description: row.descriptions?.[locale] ?? null },
      });
    }

    seeded++;
  }

  return { seeded, message: `Seeded ${seeded} foods.` };
}
