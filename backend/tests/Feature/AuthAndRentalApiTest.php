<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use App\Services\PricingConfigService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthAndRentalApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PricingConfigService::class)->seedDefaults();
    }

    public function test_user_can_register_login_and_device_role_is_blocked_from_bike_list(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'New User',
            'email' => 'new-user@example.test',
            'password' => 'password',
        ])->assertCreated()
            ->assertJsonStructure(['user' => ['id', 'email', 'role'], 'token']);

        $this->postJson('/api/auth/login', [
            'email' => 'new-user@example.test',
            'password' => 'password',
        ])->assertOk()
            ->assertJsonStructure(['user', 'token']);

        $device = User::query()->create([
            'name' => 'Device',
            'email' => 'device@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);

        Sanctum::actingAs($device);

        $this->getJson('/api/bikes')->assertForbidden();
    }

    public function test_user_can_start_only_one_active_rental_and_finish_it(): void
    {
        $user = User::query()->create([
            'name' => 'User',
            'email' => 'user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create(['code' => 'BIKE-T1', 'name' => 'Bike Test', 'status' => 'available']);
        $secondBike = Bike::query()->create(['code' => 'BIKE-T2', 'name' => 'Bike Test 2', 'status' => 'available']);

        Sanctum::actingAs($user);

        $rentalId = $this->postJson('/api/rentals/start', ['bike_id' => $bike->id])
            ->assertCreated()
            ->json('data.id');

        $this->assertDatabaseHas('bikes', ['id' => $bike->id, 'status' => 'in_use']);

        $this->postJson('/api/rentals/start', ['bike_id' => $secondBike->id])
            ->assertUnprocessable();

        $this->postJson("/api/rentals/{$rentalId}/finish")
            ->assertOk()
            ->assertJsonPath('data.status', Rental::STATUS_COMPLETED);

        $this->assertDatabaseHas('bikes', ['id' => $bike->id, 'status' => 'available']);
    }
}
