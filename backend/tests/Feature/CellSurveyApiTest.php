<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\CellHandoverEvent;
use App\Models\CellObservation;
use App\Models\CellTower;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CellSurveyApiTest extends TestCase
{
    use RefreshDatabase;

    private User $device;

    private Bike $bike;

    protected function setUp(): void
    {
        parent::setUp();

        $this->device = User::query()->create([
            'name' => 'Bike Device',
            'email' => 'device-cell@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);

        $this->bike = Bike::query()->create([
            'code' => 'CELL-01',
            'name' => 'Cell Survey Bike',
            'status' => 'available',
            'assigned_device_user_id' => $this->device->id,
        ]);
    }

    public function test_location_update_with_new_cell_creates_tower_and_observation(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', $this->payload([
            'cell_id' => '123456789',
            'signal_dbm' => -83,
            'rsrp_dbm' => -95,
        ]))->assertOk();

        $this->assertDatabaseHas('cell_towers', [
            'radio_type' => 'LTE',
            'operator_name' => 'Telkomsel',
            'operator_label' => 'Telkomsel',
            'network_operator_code' => '51010',
            'active_data_subscription_id' => 2,
            'mcc' => '510',
            'mnc' => '10',
            'cell_id' => '123456789',
            'tac_or_lac' => '4567',
            'observation_count' => 1,
            'position_observation_count' => 1,
        ]);

        $this->assertDatabaseHas('cell_observations', [
            'bike_id' => $this->bike->id,
            'device_user_id' => $this->device->id,
            'signal_dbm' => -83,
            'rsrp_dbm' => -95,
            'is_registered' => true,
            'operator_label' => 'Telkomsel',
            'network_operator_code' => '51010',
            'active_data_subscription_id' => 2,
        ]);
    }

    public function test_same_cell_updates_existing_tower_estimate_without_duplicate(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', $this->payload([
            'cell_id' => '222',
            'signal_dbm' => -90,
        ]))->assertOk();

        $this->postJson('/api/device/location-update', $this->payload([
            'latitude' => -8.584000,
            'longitude' => 116.117000,
            'cell_id' => '222',
            'signal_dbm' => -80,
        ]))->assertOk();

        $this->assertSame(1, CellTower::query()->count());
        $this->assertSame(2, CellObservation::query()->count());

        $tower = CellTower::query()->firstOrFail();
        $this->assertSame(2, $tower->observation_count);
        $this->assertSame(2, $tower->position_observation_count);
        $this->assertEquals(-85.0, (float) $tower->average_signal_dbm);
        $this->assertEquals(-8.5835, (float) $tower->estimated_latitude);
        $this->assertEquals(116.1165, (float) $tower->estimated_longitude);
    }

    public function test_cell_change_creates_handover_event(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', $this->payload(['cell_id' => 'old-cell']))->assertOk();
        $this->postJson('/api/device/location-update', $this->payload([
            'latitude' => -8.584000,
            'longitude' => 116.117000,
            'cell_id' => 'new-cell',
        ]))->assertOk();

        $this->assertSame(2, CellTower::query()->count());
        $this->assertSame(1, CellHandoverEvent::query()->count());

        $event = CellHandoverEvent::query()->firstOrFail();
        $this->assertNotNull($event->from_cell_tower_id);
        $this->assertNotNull($event->to_cell_tower_id);
        $this->assertNotSame($event->from_cell_tower_id, $event->to_cell_tower_id);
    }

    public function test_location_update_without_cell_payload_still_works(): void
    {
        Sanctum::actingAs($this->device);

        $this->postJson('/api/device/location-update', [
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'accuracy_meters' => 8,
            'network_type' => '4G/3G',
            'recorded_at' => now()->toISOString(),
        ])->assertOk();

        $this->assertSame(0, CellTower::query()->count());
        $this->assertSame(0, CellObservation::query()->count());
    }

    public function test_legacy_cell_payload_without_active_data_fields_still_records(): void
    {
        Sanctum::actingAs($this->device);

        $payload = $this->payload(['cell_id' => 'legacy-cell']);
        unset(
            $payload['cell']['operator_label'],
            $payload['cell']['network_operator_code'],
            $payload['cell']['active_data_subscription_id'],
        );

        $this->postJson('/api/device/location-update', $payload)->assertOk();

        $tower = CellTower::query()->firstOrFail();
        $this->assertSame('Telkomsel', $tower->operator_label);
        $this->assertNull($tower->network_operator_code);
        $this->assertNull($tower->active_data_subscription_id);
    }

    public function test_non_device_role_cannot_submit_cell_survey_data(): void
    {
        $user = User::query()->create([
            'name' => 'Regular User',
            'email' => 'regular-cell@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/device/location-update', $this->payload(['cell_id' => 'blocked-cell']))
            ->assertForbidden();
    }

    private function payload(array $overrides = []): array
    {
        $cell = array_merge([
            'radio_type' => 'LTE',
            'operator_name' => 'Telkomsel',
            'operator_label' => 'Telkomsel',
            'network_operator_code' => '51010',
            'active_data_subscription_id' => 2,
            'mcc' => '510',
            'mnc' => '10',
            'cell_id' => '123456789',
            'tac_or_lac' => '4567',
            'pci_or_psc' => '12',
            'signal_dbm' => -83,
            'rsrp_dbm' => -95,
            'rsrq_db' => -9.5,
            'sinr_db' => 12.0,
            'is_registered' => true,
        ], array_diff_key($overrides, array_flip(['latitude', 'longitude', 'accuracy_meters'])));

        return [
            'latitude' => $overrides['latitude'] ?? -8.583000,
            'longitude' => $overrides['longitude'] ?? 116.116000,
            'accuracy_meters' => $overrides['accuracy_meters'] ?? 8,
            'network_type' => '4G/3G',
            'recorded_at' => now()->toISOString(),
            'cell' => $cell,
        ];
    }
}
