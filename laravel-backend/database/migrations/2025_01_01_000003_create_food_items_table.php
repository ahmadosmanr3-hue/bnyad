<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Static food database (previously hard-coded in the Flutter constants).
 * Macros are per `serving_size` of `serving_unit` (default 100 g).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_items', function (Blueprint $table) {
            $table->id();
            // Original in-app identifier (e.g. "p8", "b14") so existing logs and
            // favorites that reference the string id can still be matched.
            $table->string('external_id')->nullable()->unique();
            $table->string('category')->nullable();

            $table->decimal('calories', 8, 2);
            $table->decimal('protein', 8, 2);
            $table->decimal('carbs', 8, 2);
            $table->decimal('fats', 8, 2);
            $table->decimal('serving_size', 8, 2)->default(100);
            $table->string('serving_unit')->default('g');

            // Micronutrients map: { "iron": 1.2, "calcium": 30, ... }
            $table->json('micros')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_items');
    }
};
