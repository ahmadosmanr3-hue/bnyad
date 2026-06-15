<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MealReminderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'meal_type' => $this->meal_type,
            'enabled' => $this->enabled,
            'reminder_time' => $this->reminder_time?->format('H:i'),
        ];
    }
}
