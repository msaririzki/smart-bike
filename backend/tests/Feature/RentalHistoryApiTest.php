<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RentalHistoryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_view_their_rental_detail_with_valid_route_points_only(): void
    {
        [$user, $bike, $rental] = $this->createCompletedRental();

        $newer = $this->createPoint($rental, $bike, now()->subMinute(), true, -8.5776, 116.1264);
        $older = $this->createPoint($rental, $bike, now()->subMinutes(3), true, -8.5780, 116.1260);
        $this->createPoint($rental, $bike, now()->subMinutes(2), false, -8.5790, 116.1270);

        Sanctum::actingAs($user);

        $response = $this->getJson("/api/rentals/{$rental->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $rental->id)
            ->assertJsonPath('data.bike.id', $bike->id)
            ->assertJsonCount(2, 'data.location_points');

        $this->assertSame([$older->id, $newer->id], array_column($response->json('data.location_points'), 'id'));
    }

    public function test_user_cannot_view_another_users_rental_detail(): void
    {
        [, , $rental] = $this->createCompletedRental();
        $otherUser = User::query()->create([
            'name' => 'Other User',
            'email' => 'rental-history-other@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);

        Sanctum::actingAs($otherUser);

        $this->getJson("/api/rentals/{$rental->id}")
            ->assertNotFound();
    }

    public function test_user_can_delete_completed_history_but_not_active_rental(): void
    {
        [$user, , $completedRental] = $this->createCompletedRental();
        $activeBike = Bike::query()->create([
            'code' => 'HIST-ACTIVE',
            'name' => 'Active History Bike',
            'status' => 'in_use',
        ]);
        $activeRental = Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $activeBike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now()->subMinutes(5),
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/rentals/{$activeRental->id}")
            ->assertStatus(400);
        $this->assertDatabaseHas('rentals', ['id' => $activeRental->id]);

        $this->deleteJson("/api/rentals/{$completedRental->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Riwayat rental berhasil dihapus.');
        $this->assertDatabaseMissing('rentals', ['id' => $completedRental->id]);
    }

    /**
     * @return array{0: User, 1: Bike, 2: Rental}
     */
    private function createCompletedRental(): array
    {
        $user = User::query()->create([
            'name' => 'History User',
            'email' => 'rental-history-user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'HIST-01',
            'name' => 'History Bike',
            'status' => 'available',
        ]);
        $rental = Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_COMPLETED,
            'started_at' => now()->subHour(),
            'ended_at' => now()->subMinutes(30),
            'total_distance_meters' => 1500,
            'distance_cost' => 1500,
            'idle_cost' => 0,
            'total_cost' => 1500,
        ]);

        return [$user, $bike, $rental];
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
