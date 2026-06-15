<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'display_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'weight' => ['sometimes', 'numeric', 'min:0', 'max:600'],
            'height' => ['sometimes', 'numeric', 'min:0', 'max:300'],
            'age' => ['sometimes', 'integer', 'min:0', 'max:120'],
            'gender' => ['sometimes', 'in:male,female'],
            'activity_level' => ['sometimes', 'string', 'max:40'],
            'goal' => ['sometimes', 'string', 'max:40'],
            'sicknesses' => ['sometimes', 'array'],
            'sicknesses.*' => ['string', 'max:80'],
            'allergies' => ['sometimes', 'array'],
            'allergies.*' => ['string', 'max:80'],
            'disabilities' => ['sometimes', 'array'],
            'disabilities.*' => ['string', 'max:80'],
            'daily_calories' => ['sometimes', 'integer', 'min:0', 'max:20000'],
            'daily_carbs' => ['sometimes', 'integer', 'min:0', 'max:5000'],
            'daily_protein' => ['sometimes', 'integer', 'min:0', 'max:5000'],
            'daily_fat' => ['sometimes', 'integer', 'min:0', 'max:5000'],
            'language' => ['sometimes', 'in:en,ar,ku'],
            'theme' => ['sometimes', 'in:light,dark'],
            'onboarded' => ['sometimes', 'boolean'],
            'target_weight' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:600'],
            'pace' => ['sometimes', 'in:relaxed,moderate,aggressive'],
            'body_fat_pct' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:100'],
            'pregnancy_status' => ['sometimes', 'in:none,pregnant,breastfeeding,planning'],
            'dietary_pattern' => ['sometimes', 'string', 'max:40'],
            'disliked_foods' => ['sometimes', 'array'],
            'disliked_foods.*' => ['string', 'max:80'],
            'cuisine_preference' => ['sometimes', 'string', 'max:40'],
            'meals_per_day' => ['sometimes', 'integer', 'min:1', 'max:10'],
            'fasting_window' => ['sometimes', 'string', 'max:10'],
            'sleep_hours' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:24'],
            'stress_level' => ['sometimes', 'in:low,medium,high'],
            'water_target_ml' => ['sometimes', 'nullable', 'integer', 'min:0', 'max:20000'],
            'medications' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'workout_days_per_week' => ['sometimes', 'integer', 'min:0', 'max:7'],
            'workout_type' => ['sometimes', 'string', 'max:20'],
            'cooking_skill' => ['sometimes', 'in:beginner,intermediate,advanced'],
            'cooking_time' => ['sometimes', 'string', 'max:10'],
        ];
    }
}
