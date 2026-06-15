<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Vitamin extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'dosage',
        'taken',
    ];

    protected $casts = [
        'taken' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
