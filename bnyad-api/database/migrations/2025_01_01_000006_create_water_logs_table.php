<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Mirrors the Firestore `waterLogs` collection (doc id was `{uid}_{date}`).
 * One row per user per day.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('water_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('log_date');
            $table->unsignedInteger('glasses')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'log_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('water_logs');
    }
};
