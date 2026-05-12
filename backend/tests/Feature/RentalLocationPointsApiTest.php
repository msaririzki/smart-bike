<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RentalLocationPointsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_view_valid_location_points_for_their_rental(): void
    {
        $user = User::query()->create([
            'name' => 'Map User',
            'email' => 'map-user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'MAP-01',
            'name' => 'Map Bike',
            'status' => 'in_use',
        ]);
        $rental = Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now()->subMinutes(10),
        ]);

        $newer = $this->createPoint($rental, $bike, now()->subMinute(), true, -8.5776, 116.1264);
        $older = $this->createPoint($rental, $bike, now()->subMinutes(3), true, -8.5780, 116.1260);
        $this->createPoint($rental, $bike, now()->subMinutes(2), false, -8.5790, 116.1270);

        Sanctum::actingAs($user);

        $response = $this->getJson("/api/rentals/{$rental->id}/location-points")
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->assertSame([$older->id, $newer->id], array_column($response->json('data'), 'id'));
    }

    public function test_user_cannot_view_location_points_for_another_users_rental(): void
    {
        $owner = User::query()->create([
            'name' => 'Owner',
            'email' => 'owner@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $otherUser = User::query()->create([
            'name' => 'Other User',
            'email' => 'other@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'MAP-02',
            'name' => 'Private Bike',
            'status' => 'in_use',
        ]);
        $rental = Rental::query()->create([
            'user_id' => $owner->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now()->subMinutes(10),
        ]);
        $this->createPoint($rental, $bike, now(), true, -8.5776, 116.1264);

        Sanctum::actingAs($otherUser);

        $this->getJson("/api/rentals/{$rental->id}/location-points")
            ->assertNotFound();
    }

    private function createPoint(
        Rental $rental,
        Bike $bike,
        \DateTimeInterface $recordedAt,
        bool $isValidMovement,
        float $latitude,
        float $longitude,
    ): RentalLocationPoint {
        return RentalLocationPoint::query()->create([
            'rental_id' => $rental->id,
            'bike_id' => $bike->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'speed_kmh' => 8.5,
            'accuracy_meters' => 6,
            'movement_distance_meters' => 12,
            'is_valid_movement' => $isValidMovement,
            'is_anomaly' => false,
            'recorded_at' => $recordedAt,
        ]);
    }
}
