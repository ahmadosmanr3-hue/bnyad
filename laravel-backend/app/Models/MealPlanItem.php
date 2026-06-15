<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MealPlanItem extends Model
{
    protected $fillable = [
        'meal_plan_id',
        'slot',
        'name',
        'names',
        'ingredients',
        'instructions',
        'calories',
        'protein',
        'carbs',
        'fat',
        'micros',
    ];

    protected $casts = [
        'names' => 'array',
        'ingredients' => 'array',
        'instructions' => 'array',
        'calories' => 'integer',
        'protein' => 'integer',
        'carbs' => 'integer',
        'fat' => 'integer',
        'micros' => 'array',
    ];

    public function mealPlan(): BelongsTo
    {
        return $this->belongsTo(MealPlan::class);
    }
}
