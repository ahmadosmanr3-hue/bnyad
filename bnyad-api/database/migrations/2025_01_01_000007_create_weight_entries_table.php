<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Weight history for the weekly-summary feature
 * (was stored locally as a date -> weight map).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weight_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('log_date');
            $table->decimal('weight', 6, 2);
            $table->timestamps();

            $table->unique(['user_id', 'log_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weight_entries');
    }
};
