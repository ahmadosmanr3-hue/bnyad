<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MealPlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // Re-key items by slot so the client gets { breakfast, lunch, dinner, snacks }.
        $items = $this->whenLoaded('items', fn () => $this->items
            ->keyBy('slot')
            ->map(fn ($item) => new MealPlanItemResource($item)));

        return [
            'id' => $this->id,
            'generated_at' => $this->generated_at,
            'plan' => $items,
        ];
    }
}
