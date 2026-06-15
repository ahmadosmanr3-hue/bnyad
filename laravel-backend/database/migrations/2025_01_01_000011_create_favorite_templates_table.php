<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Saved food/meal templates for quick re-logging (was stored locally).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('favorite_templates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('food_item_id')
                ->nullable()
                ->constrained('food_items')
                ->nullOnDelete();
            $table->string('external_food_id')->nullable();

            $table->string('name');
            $table->decimal('amount', 8, 2)->default(100);
            $table->decimal('calories', 8, 2)->default(0);
            $table->decimal('protein', 8, 2)->default(0);
            $table->decimal('carbs', 8, 2)->default(0);
            $table->decimal('fat', 8, 2)->default(0);
            $table->json('micros')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('favorite_templates');
    }
};
