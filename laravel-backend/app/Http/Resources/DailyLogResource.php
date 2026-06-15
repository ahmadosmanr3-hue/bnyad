<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DailyLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'food_item_id' => $this->food_item_id,
            'external_food_id' => $this->external_food_id,
            'name' => $this->name,
            'amount' => (float) $this->amount,
            'calories' => (float) $this->calories,
            'protein' => (float) $this->protein,
            'carbs' => (float) $this->carbs,
            'fat' => (float) $this->fat,
            'micros' => $this->micros ?? [],
            'meal_type' => $this->meal_type,
            'logged_at' => $this->logged_at?->toDateString(),
            'consumed_at' => $this->consumed_at,
            'food_item' => new FoodItemResource($this->whenLoaded('foodItem')),
        ];
    }
}
