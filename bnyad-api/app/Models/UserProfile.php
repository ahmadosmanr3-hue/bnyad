<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    protected $fillable = [
        'user_id',
        'display_name',
        'weight',
        'height',
        'age',
        'gender',
        'activity_level',
        'goal',
        'sicknesses',
        'allergies',
        'disabilities',
        'daily_calories',
        'daily_carbs',
        'daily_protein',
        'daily_fat',
        'language',
        'theme',
        'onboarded',
        'target_weight',
        'pace',
        'body_fat_pct',
        'pregnancy_status',
        'dietary_pattern',
        'disliked_foods',
        'cuisine_preference',
        'meals_per_day',
        'fasting_window',
        'sleep_hours',
        'stress_level',
        'water_target_ml',
        'medications',
        'workout_days_per_week',
        'workout_type',
        'cooking_skill',
        'cooking_time',
    ];

    protected $casts = [
        'weight' => 'decimal:2',
        'height' => 'decimal:2',
        'age' => 'integer',
        'sicknesses' => 'array',
        'allergies' => 'array',
        'disabilities' => 'array',
        'daily_calories' => 'integer',
        'daily_carbs' => 'integer',
        'daily_protein' => 'integer',
        'daily_fat' => 'integer',
        'onboarded' => 'boolean',
        'target_weight' => 'decimal:2',
        'body_fat_pct' => 'decimal:2',
        'disliked_foods' => 'array',
        'meals_per_day' => 'integer',
        'sleep_hours' => 'decimal:2',
        'water_target_ml' => 'integer',
        'workout_days_per_week' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
