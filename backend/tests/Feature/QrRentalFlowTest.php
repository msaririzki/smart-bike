<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\BikeQrSession;
use App\Models\Rental;
use App\Models\User;
use App\Services\PricingConfigService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class QrRentalFlowTest extends TestCase
{
    use RefreshDatabase;

    private User $deviceUser;

    private User $user;

    private Bike $bike;

    protected function setUp(): void
    {
        parent::setUp();

        app(PricingConfigService::class)->seedDefaults();

        $this->deviceUser = User::query()->create([
            'name' => 'Device Bike 1',
            'email' => 'device1@test.example',
            'password' => 'password',
            'role' => 'device',
        ]);

        $this->user = User::query()->create([
            'name' => 'Test User',
            'email' => 'user@test.example',
            'password' => 'password',
            'role' => 'user',
        ]);

        $this->bike = Bike::query()->create([
            'code' => 'QR-BIKE-01',
            'name' => 'QR Test Bike',
            'status' => 'available',
            'assigned_device_user_id' => $this->deviceUser->id,
        ]);
    }

    public function test_device_can_generate_qr_with_assigned_bike(): void
    {
        Sanctum::actingAs($this->deviceUser);

        $this->postJson('/api/device/rental-qr')
            ->assertCreated()
            ->assertJsonStructure([
                'data' => ['token', 'payload', 'expires_at', 'bike' => ['id', 'code', 'name']],
            ]);
    }

    public function test_device_cannot_generate_qr_without_assigned_bike(): void
    {
        $orphanDevice = User::query()->create([
            'name' => 'Orphan Device',
            'email' => 'orphan@test.example',
            'password' => 'password',
            'role' => 'device',
        ]);

        Sanctum::actingAs($orphanDevice);

        $this->postJson('/api/device/rental-qr')
            ->assertUnprocessable();
    }

    public function test_user_can_start_rental_from_valid_qr(): void
    {
        Sanctum::actingAs($this->deviceUser);
        $qr = $this->postJson('/api/device/rental-qr')->json('data');

        Sanctum::actingAs($this->user);
        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertCreated()
            ->assertJsonPath('data.status', Rental::STATUS_ACTIVE);

        $this->assertDatabaseHas('bikes', ['id' => $this->bike->id, 'status' => 'in_use']);
    }

    public function test_qr_cannot_be_used_twice(): void
    {
        Sanctum::actingAs($this->deviceUser);
        $qr = $this->postJson('/api/device/rental-qr')->json('data');

        Sanctum::actingAs($this->user);
        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertCreated();

        // Finish the rental first so the user can try again
        $rental = Rental::query()->latest()->first();
        $rental->update(['status' => Rental::STATUS_COMPLETED, 'ended_at' => now()]);
        $this->bike->update(['status' => 'available']);

        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertUnprocessable();
    }

    public function test_expired_qr_cannot_be_used(): void
    {
        Sanctum::actingAs($this->deviceUser);
        $qr = $this->postJson('/api/device/rental-qr')->json('data');

        // Force expire the token
        BikeQrSession::query()->where('token', $qr['token'])->update([
            'expires_at' => now()->subMinute(),
        ]);

        Sanctum::actingAs($this->user);
        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertUnprocessable();
    }

    public function test_user_cannot_start_qr_rental_with_active_rental(): void
    {
        // Start a rental the normal way first
        Rental::query()->create([
            'user_id' => $this->user->id,
            'bike_id' => $this->bike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now(),
            'last_movement_at' => now(),
        ]);
        $this->bike->update(['status' => 'in_use']);

        // Create another bike with QR
        $bike2 = Bike::query()->create([
            'code' => 'QR-BIKE-02',
            'name' => 'QR Test Bike 2',
            'status' => 'available',
            'assigned_device_user_id' => $this->deviceUser->id,
        ]);

        // Generate QR for bike2 using a second device
        $device2 = User::query()->create([
            'name' => 'Device 2',
            'email' => 'device2@test.example',
            'password' => 'password',
            'role' => 'device',
        ]);
        $bike2->update(['assigned_device_user_id' => $device2->id]);

        Sanctum::actingAs($device2);
        $qr = $this->postJson('/api/device/rental-qr')->json('data');

        Sanctum::actingAs($this->user);
        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertUnprocessable();
    }

    public function test_qr_for_unavailable_bike_is_rejected(): void
    {
        Sanctum::actingAs($this->deviceUser);
        $qr = $this->postJson('/api/device/rental-qr')->json('data');

        // Make bike unavailable
        $this->bike->update(['status' => 'maintenance']);

        Sanctum::actingAs($this->user);
        $this->postJson('/api/rentals/start-from-qr', ['token' => $qr['token']])
            ->assertUnprocessable();
    }

    public function test_non_device_role_cannot_generate_qr(): void
    {
        Sanctum::actingAs($this->user);

        $this->postJson('/api/device/rental-qr')
            ->assertForbidden();
    }

    public function test_guest_cannot_start_rental_from_qr(): void
    {
        $this->postJson('/api/rentals/start-from-qr', ['token' => 'fake_token'])
            ->assertUnauthorized();
    }

    public function test_invalid_token_is_rejected(): void
    {
        Sanctum::actingAs($this->user);

        $this->postJson('/api/rentals/start-from-qr', ['token' => 'qr_nonexistent_token'])
            ->assertUnprocessable();
    }
}
