<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\DeviceHeartbeat;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMonitoringTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_is_redirected_to_admin_login_for_monitoring(): void
    {
        $this->get('/admin/monitoring-bikes')
            ->assertRedirect('/admin/login');
    }

    public function test_admin_can_view_bike_monitoring_list(): void
    {
        $admin = User::query()->create([
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => 'password',
            'role' => 'admin',
        ]);
        $device = User::query()->create([
            'name' => 'Device',
            'email' => 'device@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);
        $user = User::query()->create([
            'name' => 'Renter',
            'email' => 'renter@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'BIKE-MON-1',
            'name' => 'Sepeda Monitoring',
            'status' => 'in_use',
            'is_online' => true,
            'battery_percent' => 75,
            'current_latitude' => -5.147665,
            'current_longitude' => 119.432732,
            'assigned_device_user_id' => $device->id,
            'last_seen_at' => now(),
        ]);

        Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now()->subMinutes(10),
        ]);

        $this->actingAs($admin)
            ->get('/admin/monitoring-bikes?status=in_use&search=BIKE-MON')
            ->assertOk()
            ->assertSee('Monitoring Sepeda')
            ->assertSee('BIKE-MON-1')
            ->assertSee('Sepeda Monitoring')
            ->assertSee('device@example.test');
    }

    public function test_admin_can_view_bike_monitoring_detail(): void
    {
        $admin = User::query()->create([
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => 'password',
            'role' => 'admin',
        ]);
        $device = User::query()->create([
            'name' => 'Device',
            'email' => 'device@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);
        $user = User::query()->create([
            'name' => 'Renter',
            'email' => 'renter@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'BIKE-MON-2',
            'name' => 'Sepeda Detail',
            'status' => 'idle',
            'is_online' => true,
            'battery_percent' => 64,
            'current_latitude' => -5.147665,
            'current_longitude' => 119.432732,
            'assigned_device_user_id' => $device->id,
            'last_seen_at' => now(),
        ]);
        $rental = Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_IDLE_WARNING,
            'started_at' => now()->subMinutes(20),
        ]);

        DeviceHeartbeat::query()->create([
            'bike_id' => $bike->id,
            'device_user_id' => $device->id,
            'network_type' => 'wifi',
            'last_seen_at' => now(),
        ]);
        RentalLocationPoint::query()->create([
            'rental_id' => $rental->id,
            'bike_id' => $bike->id,
            'latitude' => -5.147665,
            'longitude' => 119.432732,
            'network_type' => '4g',
            'recorded_at' => now(),
        ]);

        $this->actingAs($admin)
            ->get("/admin/monitoring-bikes/{$bike->id}")
            ->assertOk()
            ->assertSee('BIKE-MON-2')
            ->assertSee('wifi')
            ->assertSee('4g')
            ->assertSee('10 Sinyal Perangkat Terakhir')
            ->assertSee('10 Lokasi Rental Terakhir');
    }
}
