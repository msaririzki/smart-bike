<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $locations = [
            'BIKE-001' => [-8.583000, 116.116000],
            'BIKE-002' => [-8.584000, 116.117000],
            'BIKE-003' => [-8.585000, 116.118000],
        ];

        foreach ($locations as $code => [$latitude, $longitude]) {
            DB::table('bikes')
                ->where('code', $code)
                ->update([
                    'current_latitude' => $latitude,
                    'current_longitude' => $longitude,
                    'updated_at' => now(),
                ]);
        }
    }

    public function down(): void
    {
        $locations = [
            'BIKE-001' => [-5.147665, 119.432732],
            'BIKE-002' => [-5.148000, 119.433100],
            'BIKE-003' => [-5.147200, 119.432300],
        ];

        foreach ($locations as $code => [$latitude, $longitude]) {
            DB::table('bikes')
                ->where('code', $code)
                ->update([
                    'current_latitude' => $latitude,
                    'current_longitude' => $longitude,
                    'updated_at' => now(),
                ]);
        }
    }
};
