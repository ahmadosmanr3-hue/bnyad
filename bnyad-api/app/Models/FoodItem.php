<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FoodItem extends Model
{
    protected $fillable = [
        'external_id',
        'category',
        'calories',
        'protein',
        'carbs',
        'fats',
        'serving_size',
        'serving_unit',
        'micros',
    ];

    protected $casts = [
        'calories' => 'decimal:2',
        'protein' => 'decimal:2',
        'carbs' => 'decimal:2',
        'fats' => 'decimal:2',
        'serving_size' => 'decimal:2',
        'micros' => 'array',
    ];

    protected $appends = ['localized_name', 'localized_description'];

    // ── Relationships ────────────────────────────────────

    public function translations(): HasMany
    {
        return $this->hasMany(FoodItemTranslation::class);
    }

    public function dailyLogs(): HasMany
    {
        return $this->hasMany(DailyLog::class);
    }

    // ── Localization ─────────────────────────────────────

    /**
     * The app uses "ku" for Kurdish while the DB stores "ckb".
     * Normalize so either works.
     */
    protected function normalizedLocale(?string $locale = null): string
    {
        $locale = $locale ?: app()->getLocale();

        return $locale === 'ku' ? 'ckb' : $locale;
    }

    public function translationForLocale(?string $locale = null): ?FoodItemTranslation
    {
        $target = $this->normalizedLocale($locale);

        // Prefer the requested locale, then fall back through en -> ar -> ckb.
        foreach ([$target, 'en', 'ar', 'ckb'] as $candidate) {
            $match = $this->translations->firstWhere('locale', $candidate);
            if ($match) {
                return $match;
            }
        }

        return $this->translations->first();
    }

    public function getLocalizedNameAttribute(): ?string
    {
        return $this->translationForLocale()?->name;
    }

    public function getLocalizedDescriptionAttribute(): ?string
    {
        return $this->translationForLocale()?->description;
    }
}
