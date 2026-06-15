<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Translation Table Pattern for food items.
 * locale: en | ar | ckb (Kurdish Sorani).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_item_translations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('food_item_id')
                ->constrained('food_items')
                ->cascadeOnDelete();
            $table->string('locale', 5);
            $table->string('name');
            $table->text('description')->nullable();
            $table->timestamps();

            $table->unique(['food_item_id', 'locale']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_item_translations');
    }
};
