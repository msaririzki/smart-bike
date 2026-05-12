<?php

namespace Tests\Feature;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dashboard_rentals_users_reports_and_alerts_render(): void
    {
        $admin = User::query()->create([
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => 'password',
            'role' => 'admin',
        ]);
        $user = User::query()->create([
            'name' => 'User',
            'email' => 'user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create([
            'code' => 'BIKE-ADMIN-1',
            'name' => 'Bike Admin',
            'status' => 'available',
            'is_online' => false,
            'battery_percent' => 15,
            'current_latitude' => -8.583000,
            'current_longitude' => 116.116000,
        ]);
        $rental = Rental::query()->create([
            'user_id' => $user->id,
            'bike_id' => $bike->id,
            'status' => Rental::STATUS_ACTIVE,
            'started_at' => now()->subMinutes(5),
        ]);
        RentalLocationPoint::query()->create([
            'rental_id' => $rental->id,
            'bike_id' => $bike->id,
            'latitude' => -8.583000,
            'longitude' => 116.116000,
            'recorded_at' => now(),
        ]);

        $this->actingAs($admin);
        $this->withoutExceptionHandling();

        $this->get('/admin')->assertOk()->assertSee('Sepeda Tersedia');
        $this->get('/admin/dashboard/map-data')->assertOk()->assertJsonPath('data.0.code', 'BIKE-ADMIN-1');
        $this->get('/admin/rentals?status=running')->assertOk()->assertSee('rental berjalan');
        $this->get("/admin/rentals/{$rental->id}/route-map-data")->assertOk()->assertJsonPath('data.0.latitude', -8.583000);
        $this->get('/admin/users')->assertOk()->assertSee('Manajemen Pengguna');
        $this->get("/admin/users/{$user->id}")->assertOk()->assertSee('Histori Rental Pengguna');
        $this->get('/admin/reports')->assertOk()->assertSee('Sepeda Paling Sering Dipakai');
        $this->get('/admin/alerts')->assertOk()->assertSee('Baterai Rendah');
    }

    public function test_superadmin_can_update_user_role(): void
    {
        $superadmin = User::query()->create([
            'name' => 'Super Admin',
            'email' => 'superadmin@example.test',
            'password' => 'password',
            'role' => 'superadmin',
        ]);
        $user = User::query()->create([
            'name' => 'User',
            'email' => 'user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);

        $this->actingAs($superadmin)
            ->put("/admin/users/{$user->id}/role", ['role' => 'admin'])
            ->assertRedirect("/admin/users/{$user->id}");

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'role' => 'admin',
        ]);
    }
}
