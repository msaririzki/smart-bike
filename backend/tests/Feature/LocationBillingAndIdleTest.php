<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use App\Services\IdleDetectionService;
use App\Services\PricingConfigService;
use App\Services\RentalService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LocationBillingAndIdleTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private User $device;

    private Bike $bike;

    private Rental $rental;

    protected function setUp(): void
    {
        parent::setUp();

        app(PricingConfigService::class)->seedDefaults();

        $this->user = User::query()->create([
            'name' => 'User',
            'email' => 'user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $this->device = User::query()->create([
            'name' => 'Device',
            'email' => 'device@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);
        $this->bike = Bike::query()->create([
            'code' => 'BIKE-GPS',
            'name' => 'GPS Bike',
            'status' => 'available',
            'is_online' => true,
            'assigned_device_user_id' => $this->device->id,
        ]);
        $this->rental = app(RentalService::class)->start($this->user, $this->bike);
    }

    public function test_bad_accuracy_and_below_threshold_points_do_not_increase_billing(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subMinutes(2)->toISOString(),
        ])->assertOk();

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583001,
            'longitude' => 116.116001,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subMinute()->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Movement below threshold; not billed.');

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.584000,
            'longitude' => 116.116000,
            'accuracy_meters' => 50,
            'recorded_at' => now()->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'GPS accuracy too low for billing.');

        $this->rental->refresh();
        $this->assertSame('0.00', $this->rental->total_distance_meters);
        $this->assertSame(0, $this->rental->distance_cost);
    }

    public function test_stationary_gps_jitter_with_zero_speed_does_not_increase_billing(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'speed_kmh' => 0,
            'accuracy_meters' => 12,
            'recorded_at' => now()->subSeconds(30)->toISOString(),
        ])->assertOk();

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.582600,
            'longitude' => 116.116000,
            'speed_kmh' => 0,
            'accuracy_meters' => 12,
            'recorded_at' => now()->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Stationary GPS jitter ignored; not billed.');

        $this->rental->refresh();
        $this->assertSame('0.00', $this->rental->total_distance_meters);
        $this->assertSame(0, $this->rental->distance_cost);
        $this->assertDatabaseHas('rental_location_points', [
            'rental_id' => $this->rental->id,
            'ignored_reason' => 'stationary_jitter',
            'is_valid_movement' => false,
        ]);
    }

    public function test_valid_movement_increases_distance_cost_and_speed_anomaly_is_ignored(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subMinutes(2)->toISOString(),
        ])->assertOk();

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.582000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subMinute()->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Valid movement processed.');

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.576000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subSeconds(55)->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Over-speed movement recorded but not billed.');

        $this->rental->refresh();
        $this->assertGreaterThan(100, (float) $this->rental->total_distance_meters);
        $this->assertSame(500, $this->rental->distance_cost);
        $this->assertDatabaseHas('rental_location_points', [
            'rental_id' => $this->rental->id,
            'ignored_reason' => 'speed_anomaly',
            'is_anomaly' => true,
        ]);
    }

    public function test_tracking_and_billing_resume_from_speed_anomaly_anchor(): void
    {
        Sanctum::actingAs($this->device);

        $baseTime = now()->subMinutes(5);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => $baseTime->toISOString(),
        ])->assertOk();

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.582000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => $baseTime->copy()->addMinutes(2)->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Valid movement processed.');

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.580000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => $baseTime->copy()->addMinutes(2)->addSeconds(5)->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Over-speed movement recorded but not billed.');

        $distanceBeforeResume = (float) $this->rental->refresh()->total_distance_meters;

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.579000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => $baseTime->copy()->addMinutes(2)->addSeconds(30)->toISOString(),
        ])->assertOk()
            ->assertJsonPath('message', 'Valid movement processed.');

        $this->rental->refresh();

        $this->assertGreaterThan($distanceBeforeResume + 100, (float) $this->rental->total_distance_meters);
        $this->assertLessThan($distanceBeforeResume + 130, (float) $this->rental->total_distance_meters);
        $this->assertSame(1000, $this->rental->distance_cost);
    }

    public function test_device_can_read_active_rental_dashboard_summary_for_assigned_bike(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'speed_kmh' => 12.5,
            'accuracy_meters' => 5,
            'network_type' => 'wifi',
            'recorded_at' => now()->subMinute()->toISOString(),
        ])->assertOk();

        $this->getJson('/api/device/active-rental-summary')
            ->assertOk()
            ->assertJsonPath('data.bike.code', 'BIKE-GPS')
            ->assertJsonPath('data.rental.id', $this->rental->id)
            ->assertJsonPath('data.rental.status', Rental::STATUS_ACTIVE)
            ->assertJsonPath('data.rental.user.name', 'User')
            ->assertJsonPath('data.rental.latest_location_point.network_type', 'wifi')
            ->assertJsonPath('data.rental.current_speed_kmh', 12.5);
    }

    public function test_device_location_update_restores_stale_offline_status_during_active_rental(): void
    {
        $this->bike->update([
            'status' => 'offline',
            'is_online' => false,
        ]);

        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'speed_kmh' => 0,
            'accuracy_meters' => 8,
            'recorded_at' => now()->toISOString(),
        ])->assertOk();

        $this->bike->refresh();
        $this->assertSame('in_use', $this->bike->status);
        $this->assertTrue($this->bike->is_online);
    }

    public function test_device_qr_request_restores_stale_offline_status_when_available(): void
    {
        $this->rental->update([
            'status' => Rental::STATUS_COMPLETED,
            'ended_at' => now(),
        ]);
        $this->bike->update([
            'status' => 'offline',
            'is_online' => false,
        ]);

        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/rental-qr')
            ->assertCreated()
            ->assertJsonPath('data.bike.code', 'BIKE-GPS');

        $this->bike->refresh();
        $this->assertSame('available', $this->bike->status);
        $this->assertTrue($this->bike->is_online);
    }

    public function test_idle_warning_idle_billing_and_resume_after_valid_movement(): void
    {
        $this->rental->update(['last_movement_at' => now()->subSeconds(301)]);

        app(IdleDetectionService::class)->checkIdleWarnings();

        $this->rental->refresh();
        $this->assertSame(Rental::STATUS_IDLE_WARNING, $this->rental->status);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user->id,
            'type' => 'idle_warning',
        ]);

        Sanctum::actingAs($this->user);
        $this->postJson("/api/rentals/{$this->rental->id}/idle/continue")
            ->assertOk()
            ->assertJsonPath('data.status', Rental::STATUS_IDLE_WARNING);

        $this->assertDatabaseHas('rental_idle_events', [
            'rental_id' => $this->rental->id,
            'event_type' => 'warning_acknowledged',
        ]);

        $this->rental->refresh()->update(['idle_warning_at' => now()->subSeconds(61)]);
        app(IdleDetectionService::class)->moveWarningsToIdleBilling();

        $this->rental->refresh()->update(['last_idle_billing_at' => now()->subSeconds(301)]);
        app(IdleDetectionService::class)->applyIdleBillingDue();

        $this->rental->refresh();
        $this->assertSame(200, $this->rental->idle_cost);

        Sanctum::actingAs($this->device);
        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->subMinutes(2)->toISOString(),
        ])->assertOk();
        $this->postJson('/api/device/location-update', [
            'latitude' => -8.582000,
            'longitude' => 116.116000,
            'accuracy_meters' => 5,
            'recorded_at' => now()->toISOString(),
        ])->assertOk();

        $this->assertSame(Rental::STATUS_ACTIVE, $this->rental->refresh()->status);
    }
}
