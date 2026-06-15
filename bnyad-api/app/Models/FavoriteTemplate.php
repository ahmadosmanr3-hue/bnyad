<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FavoriteTemplate extends Model
{
    protected $fillable = [
        'user_id',
        'food_item_id',
        'external_food_id',
        'name',
        'amount',
        'calories',
        'protein',
        'carbs',
        'fat',
        'micros',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'calories' => 'decimal:2',
        'protein' => 'decimal:2',
        'carbs' => 'decimal:2',
        'fat' => 'decimal:2',
        'micros' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function foodItem(): BelongsTo
    {
        return $this->belongsTo(FoodItem::class);
    }
}
