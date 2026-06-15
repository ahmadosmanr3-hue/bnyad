<?php

namespace Database\Seeders;

use App\Models\FoodItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

/**
 * Seeds the food catalog with translations (en / ar / ckb).
 *
 * Two modes:
 *  1. If `database/data/food_items.json` exists, it is bulk-imported
 *     (recommended — export the full Flutter `foodDatabase` to this file).
 *  2. Otherwise a small representative sample is inserted so the API works
 *     out of the box.
 *
 * Expected JSON shape (array of objects):
 * [
 *   {
 *     "external_id": "p8",
 *     "category": "Protein",
 *     "calories": 155, "protein": 11, "carbs": 1.1, "fats": 11,
 *     "serving_size": 100, "serving_unit": "g",
 *     "micros": { "vitA": 160, "iron": 1.8 },
 *     "names": { "en": "Whole Egg", "ar": "بيضة كاملة", "ckb": "هێلکە" }
 *   }
 * ]
 */
class FoodItemSeeder extends Seeder
{
    public function run(): void
    {
        $jsonPath = database_path('data/food_items.json');

        $items = File::exists($jsonPath)
            ? json_decode(File::get($jsonPath), true)
            : $this->sampleItems();

        foreach ($items as $row) {
            $food = FoodItem::updateOrCreate(
                ['external_id' => $row['external_id'] ?? null],
                [
                    'category' => $row['category'] ?? null,
                    'calories' => $row['calories'] ?? 0,
                    'protein' => $row['protein'] ?? 0,
                    'carbs' => $row['carbs'] ?? 0,
                    'fats' => $row['fats'] ?? ($row['fat'] ?? 0),
                    'serving_size' => $row['serving_size'] ?? 100,
                    'serving_unit' => $row['serving_unit'] ?? 'g',
                    'micros' => $row['micros'] ?? null,
                ],
            );

            foreach (($row['names'] ?? []) as $locale => $name) {
                if (! $name) {
                    continue;
                }
                $food->translations()->updateOrCreate(
                    ['locale' => $locale],
                    ['name' => $name, 'description' => $row['descriptions'][$locale] ?? null],
                );
            }
        }
    }

    /**
     * A representative slice of the in-app database (per 100 g).
     * The app uses "ku"; it is stored here as the ISO code "ckb".
     */
    private function sampleItems(): array
    {
        return [
            [
                'external_id' => 'p1', 'category' => 'Protein',
                'calories' => 165, 'protein' => 31, 'carbs' => 0, 'fats' => 3.6,
                'micros' => ['vitB12' => 0.3, 'iron' => 1.0, 'potassium' => 256, 'zinc' => 1.0],
                'names' => ['en' => 'Grilled Chicken Breast', 'ar' => 'صدر دجاج مشوي', 'ckb' => 'سنگی مریشکی برژاو'],
            ],
            [
                'external_id' => 'p8', 'category' => 'Protein',
                'calories' => 155, 'protein' => 11, 'carbs' => 1.1, 'fats' => 11,
                'micros' => ['vitA' => 160, 'vitB12' => 0.9, 'vitD' => 2.0, 'iron' => 1.8, 'calcium' => 56],
                'names' => ['en' => 'Whole Egg', 'ar' => 'بيضة كاملة', 'ckb' => 'هێلکە'],
            ],
            [
                'external_id' => 'p2', 'category' => 'Protein',
                'calories' => 208, 'protein' => 20, 'carbs' => 0, 'fats' => 13,
                'micros' => ['vitD' => 11.0, 'vitB12' => 3.2, 'potassium' => 363],
                'names' => ['en' => 'Salmon Fillet', 'ar' => 'فيليه سلمون', 'ckb' => 'فیلەی سەلمۆن'],
            ],
            [
                'external_id' => 'g2', 'category' => 'Grains',
                'calories' => 130, 'protein' => 2.7, 'carbs' => 28, 'fats' => 0.3,
                'micros' => ['iron' => 1.2, 'potassium' => 35],
                'names' => ['en' => 'White Rice', 'ar' => 'أرز أبيض', 'ckb' => 'برنجی سپی'],
            ],
            [
                'external_id' => 'g1', 'category' => 'Grains',
                'calories' => 111, 'protein' => 2.6, 'carbs' => 23, 'fats' => 0.9,
                'micros' => ['iron' => 0.4, 'potassium' => 43],
                'names' => ['en' => 'Brown Rice', 'ar' => 'أرز بني', 'ckb' => 'برنجی قاوەیی'],
            ],
            [
                'external_id' => 'd1', 'category' => 'Dairy',
                'calories' => 59, 'protein' => 10, 'carbs' => 3.6, 'fats' => 0.4,
                'micros' => ['vitB12' => 0.8, 'calcium' => 110, 'potassium' => 141],
                'names' => ['en' => 'Greek Yogurt', 'ar' => 'زبادي يوناني', 'ckb' => 'ماستی یۆنانی'],
            ],
            [
                'external_id' => 'k1', 'category' => 'Kurdish',
                'calories' => 150, 'protein' => 5, 'carbs' => 22, 'fats' => 6,
                'micros' => ['vitA' => 40, 'vitC' => 8, 'iron' => 1.5, 'potassium' => 200],
                'names' => ['en' => 'Dolma (Kurdish)', 'ar' => 'دولمة كوردية', 'ckb' => 'دۆڵمەی کوردی'],
            ],
            [
                'external_id' => 'k2', 'category' => 'RiceDishes',
                'calories' => 210, 'protein' => 10, 'carbs' => 30, 'fats' => 6,
                'micros' => ['iron' => 1.2, 'potassium' => 150, 'zinc' => 1.5],
                'names' => ['en' => 'Kurdish Biryani', 'ar' => 'برياني كوردي', 'ckb' => 'بریانی کوردی'],
            ],
            [
                'external_id' => 'k5', 'category' => 'Bread',
                'calories' => 293, 'protein' => 9.6, 'carbs' => 50, 'fats' => 5.5,
                'micros' => ['iron' => 2.4, 'calcium' => 45, 'potassium' => 105],
                'names' => ['en' => 'Kurdish Naan (flatbread)', 'ar' => 'خبز نان كوردي', 'ckb' => 'نانی کوردی (نان)'],
            ],
            [
                'external_id' => 'a1', 'category' => 'Arabic',
                'calories' => 166, 'protein' => 8, 'carbs' => 14, 'fats' => 10,
                'micros' => ['iron' => 2.4, 'calcium' => 49, 'potassium' => 228],
                'names' => ['en' => 'Hummus', 'ar' => 'حمص', 'ckb' => 'حومس'],
            ],
        ];
    }
}
