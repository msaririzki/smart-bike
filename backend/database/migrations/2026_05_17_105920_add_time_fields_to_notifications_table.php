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
        if (! Schema::hasTable('notifications')) {
            return;
        }

        if (
            Schema::hasColumn('notifications', 'start_time')
            && Schema::hasColumn('notifications', 'end_time')
        ) {
            return;
        }

        Schema::table('notifications', function (Blueprint $table) {
            if (! Schema::hasColumn('notifications', 'start_time')) {
                $table->dateTime('start_time')->nullable();
            }

            if (! Schema::hasColumn('notifications', 'end_time')) {
                $table->dateTime('end_time')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('notifications')) {
            return;
        }

        Schema::table('notifications', function (Blueprint $table) {
            $columns = array_filter([
                Schema::hasColumn('notifications', 'start_time') ? 'start_time' : null,
                Schema::hasColumn('notifications', 'end_time') ? 'end_time' : null,
            ]);

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
