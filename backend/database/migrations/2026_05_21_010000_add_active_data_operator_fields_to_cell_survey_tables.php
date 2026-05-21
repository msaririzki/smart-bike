<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cell_towers', function (Blueprint $table): void {
            $table->string('operator_label', 100)->nullable()->after('operator_name');
            $table->string('network_operator_code', 20)->nullable()->after('operator_label');
            $table->integer('active_data_subscription_id')->nullable()->after('network_operator_code');
        });

        Schema::table('cell_observations', function (Blueprint $table): void {
            $table->string('operator_label', 100)->nullable()->after('is_registered');
            $table->string('network_operator_code', 20)->nullable()->after('operator_label');
            $table->integer('active_data_subscription_id')->nullable()->after('network_operator_code');
        });
    }

    public function down(): void
    {
        Schema::table('cell_observations', function (Blueprint $table): void {
            $table->dropColumn(['operator_label', 'network_operator_code', 'active_data_subscription_id']);
        });

        Schema::table('cell_towers', function (Blueprint $table): void {
            $table->dropColumn(['operator_label', 'network_operator_code', 'active_data_subscription_id']);
        });
    }
};
