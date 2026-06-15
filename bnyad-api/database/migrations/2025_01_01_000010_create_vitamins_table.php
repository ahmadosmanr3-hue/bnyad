<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Vitamin / supplement tracker (was stored locally per user).
 * `taken` is a daily flag the app resets each new day.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vitamins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('dosage')->nullable();
            $table->boolean('taken')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vitamins');
    }
};
