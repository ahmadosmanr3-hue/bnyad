<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MealPlanItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'slot' => $this->slot,
            'name' => $this->name,
            'names' => $this->names,
            'ingredients' => $this->ingredients,
            'instructions' => $this->instructions,
            'calories' => $this->calories,
            'protein' => $this->protein,
            'carbs' => $this->carbs,
            'fat' => $this->fat,
            'micros' => $this->micros ?? [],
        ];
    }
}
