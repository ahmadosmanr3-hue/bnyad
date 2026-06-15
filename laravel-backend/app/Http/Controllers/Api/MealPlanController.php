<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMealPlanRequest;
use App\Http\Resources\MealPlanResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MealPlanController extends Controller
{
    public function show(Request $request)
    {
        $plan = $request->user()->mealPlan()->with('items')->first();

        if (! $plan) {
            return response()->json(['data' => null]);
        }

        return new MealPlanResource($plan);
    }

    /**
     * Replace the user's meal plan. Body shape:
     * { "plan": { "breakfast": {...}, "lunch": {...}, "dinner": {...}, "snacks": {...} } }
     */
    public function store(StoreMealPlanRequest $request): MealPlanResource
    {
        $user = $request->user();

        $plan = DB::transaction(function () use ($user, $request) {
            $plan = $user->mealPlan()->updateOrCreate(
                [],
                ['generated_at' => now()],
            );

            $plan->items()->delete();

            foreach ($request->validated()['plan'] as $slot => $meal) {
                $plan->items()->create([
                    'slot' => $slot,
                    'name' => $meal['name'],
                    'names' => $meal['names'] ?? null,
                    'ingredients' => $meal['ingredients'] ?? null,
                    'instructions' => $meal['instructions'] ?? null,
                    'calories' => $meal['calories'] ?? 0,
                    'protein' => $meal['protein'] ?? 0,
                    'carbs' => $meal['carbs'] ?? 0,
                    'fat' => $meal['fat'] ?? 0,
                    'micros' => $meal['micros'] ?? null,
                ]);
            }

            return $plan;
        });

        return new MealPlanResource($plan->load('items'));
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->user()->mealPlan()?->delete();

        return response()->json(['message' => 'Meal plan cleared.']);
    }
}
