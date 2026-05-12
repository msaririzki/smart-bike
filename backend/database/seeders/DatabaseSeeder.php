<?php

namespace Database\Seeders;

use App\Models\Bike;
use App\Models\User;
use App\Services\PricingConfigService;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $superadmin = User::query()->firstOrCreate(
            ['email' => 'superadmin@smartbike.test'],
            [
                'name' => 'Super Admin',
                'password' => 'password',
                'role' => 'superadmin',
                'phone' => '080000000001',
            ],
        );

        User::query()->firstOrCreate(
            ['email' => 'admin@smartbike.test'],
            [
                'name' => 'Admin',
                'password' => 'password',
                'role' => 'admin',
                'phone' => '080000000002',
            ],
        );

        User::query()->firstOrCreate(
            ['email' => 'user@smartbike.test'],
            [
                'name' => 'Demo User',
                'password' => 'password',
                'role' => 'user',
                'phone' => '080000000003',
            ],
        );

        $device = User::query()->firstOrCreate(
            ['email' => 'device@smartbike.test'],
            [
                'name' => 'Bike Device Simulator',
                'password' => 'password',
                'role' => 'device',
                'phone' => '080000000004',
            ],
        );

        app(PricingConfigService::class)->seedDefaults();

        $bikes = [
            ['code' => 'BIKE-001', 'name' => 'Sepeda Kampus 1', 'current_latitude' => -8.583000, 'current_longitude' => 116.116000, 'assigned_device_user_id' => $device->id],
            ['code' => 'BIKE-002', 'name' => 'Sepeda Kampus 2', 'current_latitude' => -8.584000, 'current_longitude' => 116.117000],
            ['code' => 'BIKE-003', 'name' => 'Sepeda Kampus 3', 'current_latitude' => -8.585000, 'current_longitude' => 116.118000],
        ];

        foreach ($bikes as $bike) {
            Bike::query()->firstOrCreate(
                ['code' => $bike['code']],
                array_merge([
                    'status' => 'available',
                    'is_online' => false,
                    'battery_percent' => 90,
                ], $bike),
            );
        }
    }
}
