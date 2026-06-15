<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'display_name' => $this->display_name,
            'weight' => (float) $this->weight,
            'height' => (float) $this->height,
            'age' => $this->age,
            'gender' => $this->gender,
            'activity_level' => $this->activity_level,
            'goal' => $this->goal,
            'sicknesses' => $this->sicknesses ?? [],
            'allergies' => $this->allergies ?? [],
            'disabilities' => $this->disabilities ?? [],
            'daily_calories' => $this->daily_calories,
            'daily_carbs' => $this->daily_carbs,
            'daily_protein' => $this->daily_protein,
            'daily_fat' => $this->daily_fat,
            'language' => $this->language,
            'theme' => $this->theme,
            'onboarded' => $this->onboarded,
            'target_weight' => $this->target_weight !== null ? (float) $this->target_weight : null,
            'pace' => $this->pace,
            'body_fat_pct' => $this->body_fat_pct !== null ? (float) $this->body_fat_pct : null,
            'pregnancy_status' => $this->pregnancy_status,
            'dietary_pattern' => $this->dietary_pattern,
            'disliked_foods' => $this->disliked_foods ?? [],
            'cuisine_preference' => $this->cuisine_preference,
            'meals_per_day' => $this->meals_per_day,
            'fasting_window' => $this->fasting_window,
            'sleep_hours' => $this->sleep_hours !== null ? (float) $this->sleep_hours : null,
            'stress_level' => $this->stress_level,
            'water_target_ml' => $this->water_target_ml,
            'medications' => $this->medications,
            'workout_days_per_week' => $this->workout_days_per_week,
            'workout_type' => $this->workout_type,
            'cooking_skill' => $this->cooking_skill,
            'cooking_time' => $this->cooking_time,
        ];
    }
}
