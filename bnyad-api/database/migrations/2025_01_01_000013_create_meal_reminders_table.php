<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-meal reminder settings (enabled flag + time of day).
 * Was stored locally; moved server-side so settings sync across devices.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meal_reminders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('meal_type'); // breakfast | lunch | dinner | snacks
            $table->boolean('enabled')->default(false);
            $table->time('reminder_time')->default('12:00:00');
            $table->timestamps();

            $table->unique(['user_id', 'meal_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meal_reminders');
    }
};
