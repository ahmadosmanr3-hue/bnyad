<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FoodItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'external_id' => $this->external_id,
            'category' => $this->category,
            'name' => $this->localized_name,
            'description' => $this->localized_description,
            'calories' => (float) $this->calories,
            'protein' => (float) $this->protein,
            'carbs' => (float) $this->carbs,
            'fats' => (float) $this->fats,
            'serving_size' => (float) $this->serving_size,
            'serving_unit' => $this->serving_unit,
            'micros' => $this->micros ?? [],
        ];
    }
}
