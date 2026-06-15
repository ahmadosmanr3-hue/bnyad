<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mirrors the Firestore `foodLogs` collection.
 * Logs store a *snapshot* of macros (name/calories/…) so historical entries
 * stay correct even if the underlying food item changes or is deleted.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // Optional link to the canonical food item; null if it was a custom
            // / barcode / AI entry. nullOnDelete keeps the historical snapshot.
            $table->foreignId('food_item_id')
                ->nullable()
                ->constrained('food_items')
                ->nullOnDelete();
            // The original Firestore `foodId` string (in-app DB id) for matching.
            $table->string('external_food_id')->nullable();

            $table->string('name');
            $table->decimal('amount', 8, 2)->default(0);     // grams / pieces consumed
            $table->decimal('calories', 8, 2)->default(0);
            $table->decimal('protein', 8, 2)->default(0);
            $table->decimal('carbs', 8, 2)->default(0);
            $table->decimal('fat', 8, 2)->default(0);
            $table->json('micros')->nullable();

            // meal slot: breakfast | lunch | dinner | snack  (Firestore `mealId`)
            $table->string('meal_type')->nullable();

            $table->date('logged_at');                       // Firestore `date`
            $table->timestamp('consumed_at')->nullable();    // Firestore `timestamp`

            $table->timestamps();

            $table->index(['user_id', 'logged_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_logs');
    }
};
