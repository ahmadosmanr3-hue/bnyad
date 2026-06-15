<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoodItemTranslation extends Model
{
    protected $fillable = [
        'food_item_id',
        'locale',
        'name',
        'description',
    ];

    public function foodItem(): BelongsTo
    {
        return $this->belongsTo(FoodItem::class);
    }
}
