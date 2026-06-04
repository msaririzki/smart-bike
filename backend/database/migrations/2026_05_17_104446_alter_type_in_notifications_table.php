<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('notifications')) {
            return;
        }

        $driver = Schema::getConnection()->getDriverName();

        if ($driver === 'sqlite') {
            $this->rebuildNotificationsTableForSqlite();
            return;
        }

        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            DB::statement('ALTER TABLE notifications MODIFY user_id BIGINT UNSIGNED NULL');
            DB::statement("ALTER TABLE notifications MODIFY type VARCHAR(255) NOT NULL DEFAULT 'pengumuman'");
            return;
        }

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE notifications ALTER COLUMN user_id DROP NOT NULL');
            DB::statement("ALTER TABLE notifications ALTER COLUMN type TYPE VARCHAR(255)");
            DB::statement("ALTER TABLE notifications ALTER COLUMN type SET DEFAULT 'pengumuman'");
        }
    }

    private function rebuildNotificationsTableForSqlite(): void
    {
        DB::statement('PRAGMA foreign_keys=OFF;');
        DB::statement('ALTER TABLE notifications RENAME TO notifications_old');

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

        DB::statement('INSERT INTO notifications (id, user_id, rental_id, title, message, type, is_read, created_at, updated_at) SELECT id, user_id, rental_id, title, message, type, is_read, created_at, updated_at FROM notifications_old');

        Schema::drop('notifications_old');
        DB::statement('PRAGMA foreign_keys=ON;');
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
