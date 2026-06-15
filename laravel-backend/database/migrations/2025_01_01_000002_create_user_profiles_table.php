<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One-to-one extension of the user record.
 * Mirrors the Firestore `users/{uid}` document (the onboarding profile).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            $table->string('display_name')->nullable();

            // Core body / activity
            $table->decimal('weight', 6, 2)->default(70);
            $table->decimal('height', 6, 2)->default(175);
            $table->unsignedSmallInteger('age')->default(25);
            $table->string('gender')->default('male');           // male | female
            $table->string('activity_level')->default('moderatelyActive');
            $table->string('goal')->default('stayHealthy');

            // Health flags (Firestore arrays -> JSON)
            $table->json('sicknesses')->nullable();
            $table->json('allergies')->nullable();
            $table->json('disabilities')->nullable();

            // Computed macro targets
            $table->unsignedInteger('daily_calories')->default(2200);
            $table->unsignedInteger('daily_carbs')->default(250);
            $table->unsignedInteger('daily_protein')->default(120);
            $table->unsignedInteger('daily_fat')->default(70);

            // App preferences
            $table->string('language', 5)->default('en');         // en | ar | ku
            $table->string('theme')->default('light');            // light | dark
            $table->boolean('onboarded')->default(false);

            // Targets & body composition
            $table->decimal('target_weight', 6, 2)->nullable();
            $table->string('pace')->default('moderate');          // relaxed | moderate | aggressive
            $table->decimal('body_fat_pct', 5, 2)->nullable();
            $table->string('pregnancy_status')->default('none');  // none | pregnant | breastfeeding | planning

            // Diet preferences
            $table->string('dietary_pattern')->default('omnivore');
            $table->json('disliked_foods')->nullable();
            $table->string('cuisine_preference')->default('mixed');

            // Lifestyle
            $table->unsignedTinyInteger('meals_per_day')->default(3);
            $table->string('fasting_window')->default('none');
            $table->decimal('sleep_hours', 4, 2)->nullable();
            $table->string('stress_level')->default('medium');    // low | medium | high
            $table->unsignedInteger('water_target_ml')->nullable();
            $table->text('medications')->nullable();

            // Training & cooking
            $table->unsignedTinyInteger('workout_days_per_week')->default(0);
            $table->string('workout_type')->default('none');
            $table->string('cooking_skill')->default('intermediate');
            $table->string('cooking_time')->default('under30');

            $table->timestamps();

            $table->unique('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_profiles');
    }
};
