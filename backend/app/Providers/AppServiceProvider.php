<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;
use Illuminate\Pagination\Paginator;

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
        Paginator::useBootstrapFive();
        
        if ($this->app->environment('production') && str_starts_with((string) config('app.url'), 'https://')) {
            URL::forceScheme('https');
        }

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
            'distance_unit_meters' => 'Jarak per Hitungan Biaya (dalam Meter)',
            'distance_price_amount' => 'Nominal Biaya per Jarak (dalam Rupiah)',
            'rounding_mode' => 'Metode Pembulatan Jarak',
            'minimum_billable_distance_meters' => 'Jarak Minimum Dikenakan Biaya (dalam Meter)',
            'max_reasonable_speed_kmh' => 'Batas Kecepatan Maksimal Wajar (dalam KM/Jam)',
            'idle_warning_after_seconds' => 'Waktu Diam Sebelum Diberi Peringatan (dalam Detik)',
            'grace_period_before_idle_billing_seconds' => 'Waktu Tunggu Sebelum Dikenakan Denda Diam (dalam Detik)',
            'idle_billing_interval_seconds' => 'Interval Pengenaan Denda Diam (dalam Detik)',
            'idle_billing_amount' => 'Nominal Denda Berhenti/Diam (dalam Rupiah)',
            'gps_update_interval_seconds' => 'Jeda Pembaruan GPS (dalam Detik)',
            'minimum_movement_threshold_meters' => 'Batas Minimum Pergerakan Sepeda (dalam Meter)',
            'max_gps_accuracy_meters' => 'Batas Akurasi GPS (dalam Meter)',
            'offline_timeout_seconds' => 'Batas Waktu Sebelum Sepeda Berstatus Offline (dalam Detik)',
            'allow_multiple_active_rentals' => 'Izinkan Satu Akun Menyewa Banyak Sepeda',
            'maximum_rental_duration_minutes' => 'Durasi Maksimal Rental (dalam Menit)',
            'force_finish_when_offline_too_long' => 'Akhiri Sewa Otomatis Jika Terlalu Lama Offline',
        ]);

        View::share('adminSettingDescriptions', [
            'distance_unit_meters' => 'Contoh: Jika diisi 100, maka tarif baru akan bertambah setiap kali sepeda melaju sejauh 100 meter.',
            'distance_price_amount' => 'Harga yang akan dikenakan setiap kali sepeda menempuh "Jarak per Hitungan Biaya" yang telah diatur di atas.',
            'rounding_mode' => 'Cara sistem menghitung jarak akhir: isi dengan "floor" (pembulatan ke bawah), "ceil" (pembulatan ke atas), atau "round" (dibulatkan ke yang terdekat).',
            'minimum_billable_distance_meters' => 'Batas jarak minimal yang akan tetap ditagihkan walaupun pengguna berkendara kurang dari jarak tersebut.',
            'max_reasonable_speed_kmh' => 'Jika sepeda bergerak lebih cepat dari angka ini (misal sepeda sedang diangkut mobil pick-up), sistem akan mengabaikan jaraknya untuk mencegah kecurangan.',
            'idle_warning_after_seconds' => 'Waktu maksimal sepeda boleh berhenti. Jika lebih dari batas ini (misal diisi 300 detik atau 5 menit), pengguna akan menerima peringatan teguran di layar HP-nya.',
            'grace_period_before_idle_billing_seconds' => 'Waktu toleransi tambahan SETELAH pengguna diberi peringatan. Jika masih tidak bergerak, sistem akan mulai memotong saldo untuk denda parkir/berhenti.',
            'idle_billing_interval_seconds' => 'Jarak waktu pengenaan denda secara berulang (contoh: denda dipotong setiap 60 detik selama sepeda diam).',
            'idle_billing_amount' => 'Besaran nominal denda yang dipotong setiap kali interval denda diam di atas terlewati.',
            'gps_update_interval_seconds' => 'Seberapa sering (dalam hitungan detik) alat pelacak pada sepeda wajib mengirimkan data lokasinya ke server.',
            'minimum_movement_threshold_meters' => 'Jika sepeda bergeser atau bergetar namun kurang dari jarak ini, sistem akan mengabaikan pergerakan tersebut (dianggap masih diam/parkir).',
            'max_gps_accuracy_meters' => 'Jika sinyal GPS tiba-tiba buruk dan meleset lebih dari angka ini, datanya tidak akan dipakai menghitung jarak agar pengguna tidak dirugikan karena error sinyal.',
            'offline_timeout_seconds' => 'Jika alat pada sepeda kehabisan baterai/hilang sinyal dan tidak terhubung ke server selama batas detik ini, statusnya otomatis menjadi "Offline".',
            'allow_multiple_active_rentals' => 'Isi dengan "1" (Ya) atau "0" (Tidak). Menentukan apakah satu akun pengguna boleh meminjam beberapa sepeda secara bersamaan.',
            'maximum_rental_duration_minutes' => 'Batas maksimal waktu penyewaan sepeda. Isi dengan angka "0" jika Anda tidak ingin membatasi durasi penyewaan.',
            'force_finish_when_offline_too_long' => 'Isi dengan "1" (Ya) atau "0" (Tidak). Sistem akan mengakhiri masa sewa secara otomatis jika sepeda hilang sinyal/offline melewati batas wajar.',
        ]);
    }
}
