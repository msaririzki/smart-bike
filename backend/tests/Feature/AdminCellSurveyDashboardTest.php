<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\CellHandoverEvent;
use App\Models\CellObservation;
use App\Models\CellTower;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminCellSurveyDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_cell_map_is_scoped_to_selected_device_account(): void
    {
        [$admin, $deviceA, $deviceB] = $this->users();
        [$towerA, $towerB] = $this->towers();
        $bikeA = $this->bike('BIKE-A', $deviceA);
        $bikeB = $this->bike('BIKE-B', $deviceB);

        $this->observation($towerA, $bikeA, $deviceA, -8.583000, 116.116000);
        $this->observation($towerB, $bikeB, $deviceB, -8.584000, 116.117000);

        $this->actingAs($admin)
            ->get('/admin/dashboard/map-data')
            ->assertOk()
            ->assertJsonCount(0, 'cells');

        $this->actingAs($admin)
            ->get("/admin/dashboard/map-data?cell_device_id={$deviceA->id}")
            ->assertOk()
            ->assertJsonCount(1, 'cells')
            ->assertJsonPath('cells.0.cell_id', '111')
            ->assertJsonPath('cells.0.observation_count', 1);
    }

    public function test_admin_can_clear_cell_survey_for_selected_device_only(): void
    {
        [$admin, $deviceA, $deviceB] = $this->users();
        [$towerA, $towerB] = $this->towers();
        $bikeA = $this->bike('BIKE-A', $deviceA);
        $bikeB = $this->bike('BIKE-B', $deviceB);

        $this->observation($towerA, $bikeA, $deviceA, -8.583000, 116.116000);
        $this->observation($towerB, $bikeB, $deviceB, -8.584000, 116.117000);
        CellHandoverEvent::query()->create([
            'bike_id' => $bikeA->id,
            'device_user_id' => $deviceA->id,
            'from_cell_tower_id' => null,
            'to_cell_tower_id' => $towerA->id,
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'observed_at' => now(),
        ]);

        $this->actingAs($admin)
            ->post('/admin/dashboard/cell-survey/clear', ['device_user_id' => $deviceA->id])
            ->assertRedirect("/admin?cell_device_id={$deviceA->id}")
            ->assertSessionHas('status');

        $this->assertDatabaseMissing('cell_observations', ['device_user_id' => $deviceA->id]);
        $this->assertDatabaseHas('cell_observations', ['device_user_id' => $deviceB->id]);
        $this->assertDatabaseMissing('cell_handover_events', ['device_user_id' => $deviceA->id]);
        $this->assertDatabaseMissing('cell_towers', ['id' => $towerA->id]);
        $this->assertDatabaseHas('cell_towers', ['id' => $towerB->id]);
    }

    /**
     * @return array{User, User, User}
     */
    private function users(): array
    {
        $admin = User::query()->create([
            'name' => 'Admin',
            'email' => 'admin-cell@example.test',
            'password' => 'password',
            'role' => 'admin',
        ]);
        $deviceA = User::query()->create([
            'name' => 'Device A',
            'email' => 'device-a@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);
        $deviceB = User::query()->create([
            'name' => 'Device B',
            'email' => 'device-b@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);

        return [$admin, $deviceA, $deviceB];
    }

    /**
     * @return array{CellTower, CellTower}
     */
    private function towers(): array
    {
        $towerA = CellTower::query()->create([
            'identity_key' => 'tower-a',
            'radio_type' => 'LTE',
            'operator_name' => 'Tri',
            'operator_label' => 'Tri',
            'mcc' => '510',
            'mnc' => '89',
            'cell_id' => '111',
            'tac_or_lac' => '22',
            'last_seen_at' => now(),
        ]);
        $towerB = CellTower::query()->create([
            'identity_key' => 'tower-b',
            'radio_type' => 'LTE',
            'operator_name' => 'XL',
            'operator_label' => 'XL',
            'mcc' => '510',
            'mnc' => '11',
            'cell_id' => '222',
            'tac_or_lac' => '33',
            'last_seen_at' => now(),
        ]);

        return [$towerA, $towerB];
    }

    private function bike(string $code, User $device): Bike
    {
        return Bike::query()->create([
            'code' => $code,
            'name' => $code,
            'status' => 'available',
            'assigned_device_user_id' => $device->id,
        ]);
    }

    private function observation(CellTower $tower, Bike $bike, User $device, float $latitude, float $longitude): CellObservation
    {
        return CellObservation::query()->create([
            'cell_tower_id' => $tower->id,
            'bike_id' => $bike->id,
            'device_user_id' => $device->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'accuracy_meters' => 10,
            'signal_dbm' => -82,
            'is_registered' => true,
            'operator_label' => $tower->operator_label,
            'network_operator_code' => "{$tower->mcc}{$tower->mnc}",
            'observed_at' => now(),
        ]);
    }
}
