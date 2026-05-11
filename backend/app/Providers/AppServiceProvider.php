<?php

namespace App\Providers;

use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        View::share('adminStatusLabels', [
            'available' => 'tersedia',
            'reserved' => 'dipesan',
            'in_use' => 'sedang dipakai',
            'idle' => 'diam',
            'offline' => 'offline',
            'maintenance' => 'perawatan',
            'active' => 'aktif',
            'idle_warning' => 'peringatan diam',
            'idle_billing' => 'biaya diam berjalan',
            'completed' => 'selesai',
            'cancelled' => 'dibatalkan',
        ]);

        View::share('adminRoleLabels', [
            'user' => 'pengguna',
            'admin' => 'admin',
            'superadmin' => 'superadmin',
            'device' => 'perangkat sepeda',
        ]);

        View::share('adminSettingGroupLabels', [
            'Distance Billing' => 'Biaya Berdasarkan Jarak',
            'Idle Rules' => 'Aturan Sepeda Diam',
            'GPS Rules' => 'Aturan Lokasi',
            'Bike Rental Rules' => 'Aturan Rental Sepeda',
        ]);

        View::share('adminSettingLabels', [
            'distance_unit_meters' => 'Jarak per hitungan biaya',
            'distance_price_amount' => 'Biaya per jarak',
            'rounding_mode' => 'Metode pembulatan',
            'minimum_billable_distance_meters' => 'Jarak minimum yang ditagihkan',
            'max_reasonable_speed_kmh' => 'Kecepatan maksimum wajar',
            'idle_warning_after_seconds' => 'Waktu sebelum peringatan sepeda diam',
            'grace_period_before_idle_billing_seconds' => 'Waktu tunggu sebelum biaya diam',
            'idle_billing_interval_seconds' => 'Jeda penagihan biaya diam',
            'idle_billing_amount' => 'Biaya saat sepeda diam',
            'gps_update_interval_seconds' => 'Jeda update lokasi',
            'minimum_movement_threshold_meters' => 'Batas minimum pergerakan',
            'max_gps_accuracy_meters' => 'Batas akurasi lokasi',
            'offline_timeout_seconds' => 'Batas waktu offline',
            'allow_multiple_active_rentals' => 'Izinkan beberapa rental aktif',
            'maximum_rental_duration_minutes' => 'Durasi rental maksimum',
            'force_finish_when_offline_too_long' => 'Paksa selesai jika offline terlalu lama',
        ]);

        View::share('adminSettingDescriptions', [
            'distance_unit_meters' => 'Contoh: jika diisi 100, biaya dihitung setiap 100 meter.',
            'distance_price_amount' => 'Nominal biaya untuk setiap jarak di atas.',
            'rounding_mode' => 'Cara membulatkan jarak: turun, naik, atau terdekat.',
            'minimum_billable_distance_meters' => 'Jarak minimum yang tetap dihitung sebagai biaya.',
            'max_reasonable_speed_kmh' => 'Data lokasi dengan kecepatan di atas angka ini dianggap tidak wajar.',
            'idle_warning_after_seconds' => 'Berapa detik sepeda boleh diam sebelum pengguna diberi peringatan.',
            'grace_period_before_idle_billing_seconds' => 'Waktu tambahan setelah peringatan sebelum biaya diam mulai dihitung.',
            'idle_billing_interval_seconds' => 'Seberapa sering biaya diam ditambahkan.',
            'idle_billing_amount' => 'Nominal biaya yang ditambahkan setiap kali sepeda diam terlalu lama.',
            'gps_update_interval_seconds' => 'Seberapa sering perangkat sepeda diharapkan mengirim lokasi.',
            'minimum_movement_threshold_meters' => 'Pergerakan di bawah jarak ini dianggap belum berpindah.',
            'max_gps_accuracy_meters' => 'Data lokasi dengan akurasi lebih buruk dari angka ini tidak dipakai untuk biaya.',
            'offline_timeout_seconds' => 'Detik sebelum sepeda dianggap offline.',
            'allow_multiple_active_rentals' => 'Apakah satu pengguna boleh punya lebih dari satu rental aktif.',
            'maximum_rental_duration_minutes' => 'Nol berarti tidak dibatasi.',
            'force_finish_when_offline_too_long' => 'Apakah rental dipaksa selesai saat sepeda offline terlalu lama.',
        ]);
    }
}
