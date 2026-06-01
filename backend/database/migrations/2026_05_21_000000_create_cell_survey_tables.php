<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cell_towers', function (Blueprint $table) {
            $table->id();
            $table->string('identity_key')->unique();
            $table->string('radio_type', 20)->default('UNKNOWN')->index();
            $table->string('operator_name', 100)->nullable();
            $table->string('mcc', 10)->nullable();
            $table->string('mnc', 10)->nullable();
            $table->string('cell_id', 64);
            $table->string('tac_or_lac', 64)->nullable();
            $table->string('pci_or_psc', 64)->nullable();
            $table->decimal('estimated_latitude', 10, 7)->nullable();
            $table->decimal('estimated_longitude', 10, 7)->nullable();
            $table->unsignedInteger('observation_count')->default(0);
            $table->unsignedInteger('position_observation_count')->default(0);
            $table->decimal('average_signal_dbm', 6, 2)->nullable();
            $table->decimal('average_rsrp_dbm', 6, 2)->nullable();
            $table->decimal('average_rsrq_db', 6, 2)->nullable();
            $table->decimal('average_sinr_db', 6, 2)->nullable();
            $table->timestamp('first_seen_at')->nullable();
            $table->timestamp('last_seen_at')->nullable()->index();
            $table->timestamps();
        });

        Schema::create('cell_observations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cell_tower_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('rental_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('rental_location_point_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('accuracy_meters', 8, 2)->nullable();
            $table->integer('signal_dbm')->nullable();
            $table->integer('rsrp_dbm')->nullable();
            $table->decimal('rsrq_db', 6, 2)->nullable();
            $table->decimal('sinr_db', 6, 2)->nullable();
            $table->boolean('is_registered')->default(false);
            $table->timestamp('observed_at')->index();
            $table->timestamps();
        });

        Schema::create('cell_handover_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('from_cell_tower_id')->nullable()->constrained('cell_towers')->nullOnDelete();
            $table->foreignId('to_cell_tower_id')->constrained('cell_towers')->cascadeOnDelete();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->timestamp('observed_at')->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cell_handover_events');
        Schema::dropIfExists('cell_observations');
        Schema::dropIfExists('cell_towers');
    }
};
