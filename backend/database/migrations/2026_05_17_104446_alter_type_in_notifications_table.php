<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        \Illuminate\Support\Facades\DB::statement('ALTER TABLE notifications RENAME TO notifications_old');
        
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('rental_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->text('message');
            $table->string('type')->default('pengumuman');
            $table->boolean('is_read')->default(false);
            $table->timestamps();
        });

        \Illuminate\Support\Facades\DB::statement('INSERT INTO notifications (id, user_id, rental_id, title, message, type, is_read, created_at, updated_at) SELECT id, user_id, rental_id, title, message, type, is_read, created_at, updated_at FROM notifications_old');
        
        Schema::drop('notifications_old');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            //
        });
    }
};
