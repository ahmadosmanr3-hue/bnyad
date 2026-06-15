<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'profile_photo_path',
        'is_premium',
        'premium_until',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'phone_verified_at' => 'datetime',
        'premium_until' => 'datetime',
        'is_premium' => 'boolean',
        'password' => 'hashed',
    ];

    // ── Relationships ────────────────────────────────────

    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    public function dailyLogs(): HasMany
    {
        return $this->hasMany(DailyLog::class);
    }

    public function waterLogs(): HasMany
    {
        return $this->hasMany(WaterLog::class);
    }

    public function weightEntries(): HasMany
    {
        return $this->hasMany(WeightEntry::class);
    }

    public function mealPlan(): HasOne
    {
        return $this->hasOne(MealPlan::class);
    }

    public function vitamins(): HasMany
    {
        return $this->hasMany(Vitamin::class);
    }

    public function favoriteTemplates(): HasMany
    {
        return $this->hasMany(FavoriteTemplate::class);
    }

    public function shoppingItems(): HasMany
    {
        return $this->hasMany(ShoppingItem::class);
    }

    public function mealReminders(): HasMany
    {
        return $this->hasMany(MealReminder::class);
    }

    // ── Helpers ──────────────────────────────────────────

    public function isPremiumActive(): bool
    {
        if (! $this->is_premium) {
            return false;
        }

        return $this->premium_until === null || $this->premium_until->isFuture();
    }
}
