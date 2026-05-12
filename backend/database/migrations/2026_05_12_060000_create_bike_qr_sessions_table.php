<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bike_qr_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('token', 80)->unique();
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->foreignId('used_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['bike_id', 'used_at', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bike_qr_sessions');
    }
};
