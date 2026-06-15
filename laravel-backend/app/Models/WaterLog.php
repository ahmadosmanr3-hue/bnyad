<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WaterLog extends Model
{
    protected $fillable = [
        'user_id',
        'log_date',
        'glasses',
    ];

    protected $casts = [
        'log_date' => 'date',
        'glasses' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
