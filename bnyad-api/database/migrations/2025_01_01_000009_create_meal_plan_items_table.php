<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The four slots of a meal plan. Multilingual fields (names / ingredients /
 * instructions) are stored as JSON keyed by locale: { "en": ..., "ar": ..., "ku": ... }
 * because they are AI-generated free-form content rather than catalog data.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meal_plan_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('meal_plan_id')
                ->constrained('meal_plans')
                ->cascadeOnDelete();

            $table->string('slot'); // breakfast | lunch | dinner | snacks

            $table->string('name');                 // primary / fallback name
            $table->json('names')->nullable();       // { en, ar, ku }
            $table->json('ingredients')->nullable(); // { en:[], ar:[], ku:[] }
            $table->json('instructions')->nullable();

            $table->unsignedInteger('calories')->default(0);
            $table->unsignedInteger('protein')->default(0);
            $table->unsignedInteger('carbs')->default(0);
            $table->unsignedInteger('fat')->default(0);
            $table->json('micros')->nullable();

            $table->timestamps();

            $table->unique(['meal_plan_id', 'slot']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meal_plan_items');
    }
};
