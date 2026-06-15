<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MealReminder extends Model
{
    protected $fillable = [
        'user_id',
        'meal_type',
        'enabled',
        'reminder_time',
    ];

    protected $casts = [
        'enabled' => 'boolean',
        'reminder_time' => 'datetime:H:i',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
