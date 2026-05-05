<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bikes', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('status')->default('available')->index();
            $table->decimal('current_latitude', 10, 7)->nullable();
            $table->decimal('current_longitude', 10, 7)->nullable();
            $table->decimal('last_accuracy', 8, 2)->nullable();
            $table->boolean('is_online')->default(false)->index();
            $table->unsignedTinyInteger('battery_percent')->nullable();
            $table->foreignId('assigned_device_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
        });

        Schema::create('rentals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('active')->index();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('last_movement_at')->nullable();
            $table->timestamp('idle_warning_at')->nullable();
            $table->timestamp('idle_started_at')->nullable();
            $table->timestamp('last_idle_billing_at')->nullable();
            $table->decimal('total_distance_meters', 10, 2)->default(0);
            $table->unsignedInteger('distance_cost')->default(0);
            $table->unsignedInteger('idle_cost')->default(0);
            $table->unsignedInteger('total_cost')->default(0);
            $table->timestamps();
        });

        Schema::create('rental_location_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rental_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('speed_kmh', 8, 2)->nullable();
            $table->decimal('accuracy_meters', 8, 2)->nullable();
            $table->string('network_type')->nullable();
            $table->decimal('movement_distance_meters', 10, 2)->default(0);
            $table->boolean('is_valid_movement')->default(false)->index();
            $table->boolean('is_anomaly')->default(false)->index();
            $table->string('ignored_reason')->nullable();
            $table->timestamp('recorded_at');
            $table->timestamps();
        });

        Schema::create('rental_idle_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rental_id')->constrained()->cascadeOnDelete();
            $table->string('event_type');
            $table->text('description')->nullable();
            $table->timestamp('event_at');
            $table->timestamps();
        });

        Schema::create('pricing_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('value');
            $table->string('value_type')->default('string');
            $table->string('group_name')->default('general')->index();
            $table->text('description')->nullable();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('rental_billing_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rental_id')->constrained()->cascadeOnDelete();
            $table->string('billing_type');
            $table->unsignedInteger('amount');
            $table->decimal('quantity', 10, 2)->default(1);
            $table->string('unit_label')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('device_heartbeats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bike_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('network_type')->nullable();
            $table->timestamp('last_seen_at');
            $table->string('signal_note')->nullable();
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('rental_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->boolean('is_read')->default(false)->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('device_heartbeats');
        Schema::dropIfExists('rental_billing_logs');
        Schema::dropIfExists('pricing_settings');
        Schema::dropIfExists('rental_idle_events');
        Schema::dropIfExists('rental_location_points');
        Schema::dropIfExists('rentals');
        Schema::dropIfExists('bikes');
    }
};
