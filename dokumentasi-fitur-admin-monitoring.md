# Dokumentasi Fitur Admin Smart Bike

Tanggal: 11 Mei 2026  
Commit acuan: `d34ad01584c7c0ec69b74f20c70f88ef16b9016a`  
Commit message: `Add admin bike monitoring features`

---

## Ringkasan

Commit ini menambahkan dan memperluas Web Admin untuk memonitor operasional Smart Bike Rental.

Fokus utamanya:

- Admin bisa melihat kondisi sepeda.
- Admin bisa melihat posisi sepeda di peta.
- Admin bisa melihat rental aktif dan riwayat rental.
- Admin bisa melihat sinyal device sepeda.
- Admin bisa melihat peringatan operasional.
- Admin bisa melihat laporan ringkas.
- Superadmin bisa mengatur role user dan pengaturan sistem.

Fitur ini berada di Laravel backend, bukan di Flutter.

---

## Cara Mengakses Admin

Jalankan backend:

```bash
cd backend
php artisan serve
```

Buka:

```text
http://127.0.0.1:8000/admin
```

Jika belum login, akan diarahkan ke:

```text
http://127.0.0.1:8000/admin/login
```

Hak akses:

- `admin`: bisa membuka dashboard, monitoring, sepeda, rental, pengguna, laporan, dan peringatan.
- `superadmin`: bisa melakukan semua akses admin, plus pengaturan sistem dan update role user.
- `user`: tidak boleh masuk admin.
- `device`: tidak boleh masuk admin.

---

## Menu Admin yang Tersedia

### 1. Dasbor

URL:

```text
/admin
```

Route:

```text
admin.dashboard
```

File utama:

- `backend/app/Http/Controllers/Admin/DashboardController.php`
- `backend/resources/views/admin/dashboard.blade.php`

Yang ditampilkan:

- Total sepeda.
- Sepeda tersedia.
- Sepeda sedang dipakai.
- Sepeda offline.
- Rental aktif.
- Rental selesai hari ini.
- Estimasi pendapatan.
- Total jarak tempuh.
- Total pengguna.
- Peta lokasi sepeda.

Peta dashboard:

- Menggunakan Leaflet.
- Mengambil data sepeda yang punya `current_latitude` dan `current_longitude`.
- Marker dibedakan berdasarkan status sepeda.
- Popup marker menampilkan:
  - kode sepeda
  - nama sepeda
  - status
  - online/offline
  - baterai
  - jaringan
  - last seen
  - device yang ter-assign
  - rental aktif jika ada
- Peta refresh otomatis setiap 10 detik melalui endpoint JSON.

Endpoint JSON peta:

```text
GET /admin/dashboard/map-data
```

Route:

```text
admin.dashboard.map-data
```

Kegunaan untuk tim:

- Dipakai untuk melihat semua sepeda yang sudah mengirim lokasi.
- Cocok untuk demo monitoring real-time dari data `mobile_bike`.

---

### 2. Monitoring Sepeda

URL:

```text
/admin/monitoring-bikes
```

Route:

```text
admin.monitoring.index
```

File utama:

- `backend/app/Http/Controllers/Admin/MonitoringController.php`
- `backend/resources/views/admin/monitoring/index.blade.php`
- `backend/resources/views/admin/monitoring/show.blade.php`

Yang ditampilkan di list:

- Kode sepeda.
- Nama sepeda.
- Status sepeda.
- Status online/offline.
- Baterai.
- Latitude.
- Longitude.
- Terakhir aktif.
- Jenis jaringan.
- Perangkat sepeda yang ter-assign.
- Rental aktif.
- Link detail monitoring.

Filter yang tersedia:

- `all`
- `available`
- `in_use`
- `offline`
- `maintenance`

Search:

- berdasarkan kode sepeda
- berdasarkan nama sepeda

Detail monitoring sepeda:

```text
/admin/monitoring-bikes/{bike}
```

Route:

```text
admin.monitoring.show
```

Yang ditampilkan di detail:

- Status sepeda.
- Status online/offline.
- Baterai.
- Device sepeda yang ter-assign.
- Lokasi terakhir.
- Akurasi lokasi.
- Waktu lokasi terakhir diterima.
- Terakhir aktif.
- Sinyal device terakhir.
- Rental aktif jika ada.
- 10 heartbeat device terakhir.
- 10 lokasi rental terakhir.

Relasi model yang dipakai:

- `Bike::assignedDevice()`
- `Bike::activeRental()`
- `Bike::latestHeartbeat()`
- `Bike::deviceHeartbeats()`
- `Bike::latestLocationPoint()`
- `Bike::locationPoints()`

Kegunaan untuk tim:

- Tim simulator bisa memastikan device benar-benar mengirim heartbeat dan lokasi.
- Tim active rental bisa memastikan koordinat dari backend sudah masuk.
- Tim admin bisa melihat sepeda mana yang online, offline, baterai rendah, atau sedang dipakai.

---

### 3. Manajemen Sepeda

URL:

```text
/admin/bikes
```

Route:

```text
admin.bikes.index
```

File utama:

- `backend/app/Http/Controllers/Admin/BikeController.php`
- `backend/resources/views/admin/bikes/index.blade.php`
- `backend/resources/views/admin/bikes/form.blade.php`

Fitur:

- List sepeda.
- Tambah sepeda.
- Edit sepeda.
- Assign device user ke sepeda.
- Set status sepeda.
- Set lokasi awal jika diperlukan.
- Set baterai jika diperlukan.

Field penting:

- `code`
- `name`
- `status`
- `current_latitude`
- `current_longitude`
- `battery_percent`
- `assigned_device_user_id`

Status sepeda yang valid:

- `available`
- `reserved`
- `in_use`
- `idle`
- `offline`
- `maintenance`

Catatan:

Assign device penting untuk fitur GPS. Akun dengan role `device` harus dihubungkan ke sepeda lewat field `assigned_device_user_id`.

---

### 4. Rental

URL:

```text
/admin/rentals
```

Route:

```text
admin.rentals.index
```

File utama:

- `backend/app/Http/Controllers/Admin/RentalController.php`
- `backend/resources/views/admin/rentals/index.blade.php`
- `backend/resources/views/admin/rentals/show.blade.php`

Filter rental:

- `all`
- `running`
- `active`
- `idle_warning`
- `idle_billing`
- `completed`
- `cancelled`

`running` berarti rental yang masih berjalan, yaitu:

- `active`
- `idle_warning`
- `idle_billing`

Detail rental:

```text
/admin/rentals/{rental}
```

Route:

```text
admin.rentals.show
```

Yang ditampilkan:

- Data pengguna.
- Data sepeda.
- Ringkasan rental.
- Status rental.
- Waktu mulai.
- Waktu selesai.
- Durasi.
- Biaya jarak.
- Biaya idle.
- Total biaya.
- Total jarak.
- Peta rute rental.
- Lokasi terakhir.
- Riwayat tagihan.
- Catatan sepeda diam.
- Riwayat rute/lokasi.

Endpoint JSON rute rental:

```text
GET /admin/rentals/{rental}/route-map-data
```

Route:

```text
admin.rentals.route-map-data
```

Data route map berisi:

- latitude
- longitude
- speed_kmh
- accuracy_meters
- network_type
- is_valid_movement
- is_anomaly
- ignored_reason
- recorded_at

Kegunaan untuk tim:

- Tim active rental bisa membandingkan rute user dengan data admin.
- Tim simulator bisa melihat apakah titik GPS yang dikirim masuk sebagai location point.
- Tim rental history bisa memastikan data rental selesai punya rute dan biaya yang benar.

---

### 5. Manajemen Pengguna

URL:

```text
/admin/users
```

Route:

```text
admin.users.index
```

File utama:

- `backend/app/Http/Controllers/Admin/UserController.php`
- `backend/resources/views/admin/users/index.blade.php`
- `backend/resources/views/admin/users/show.blade.php`

Fitur:

- List user.
- Filter role.
- Search nama, email, atau nomor telepon.
- Detail user.
- Melihat jumlah rental user.
- Melihat histori rental user.
- Melihat sepeda yang di-assign jika user adalah device.

Role yang didukung:

- `user`
- `admin`
- `superadmin`
- `device`

Update role:

```text
PUT /admin/users/{user}/role
```

Route:

```text
admin.users.role.update
```

Catatan:

Update role hanya bisa dilakukan oleh `superadmin`.

Kegunaan untuk tim:

- Membuat akun device untuk `mobile_bike`.
- Membuat akun admin/superadmin untuk web admin.
- Mengecek user mana yang punya rental.
- Mengecek akun device mana yang di-assign ke sepeda.

---

### 6. Laporan

URL:

```text
/admin/reports
```

Route:

```text
admin.reports.index
```

File utama:

- `backend/app/Http/Controllers/Admin/ReportController.php`
- `backend/resources/views/admin/reports/index.blade.php`

Yang ditampilkan:

- Rental harian 14 hari terakhir.
- Jumlah rental per hari.
- Pendapatan per hari.
- Total jarak per hari.
- Sepeda paling sering dipakai.
- Total revenue.
- Total distance.
- Jumlah idle event.
- Rental yang paling sering terkena idle event.

Kegunaan untuk tim:

- Melihat ringkasan operasional.
- Mengetahui sepeda yang paling aktif.
- Melihat indikasi masalah idle.
- Bahan presentasi untuk sisi admin.

---

### 7. Peringatan

URL:

```text
/admin/alerts
```

Route:

```text
admin.alerts.index
```

File utama:

- `backend/app/Http/Controllers/Admin/AlertController.php`
- `backend/resources/views/admin/alerts/index.blade.php`
- `backend/resources/views/admin/alerts/partials/bike-table.blade.php`

Yang ditampilkan:

- Sepeda offline.
- Baterai rendah.
- Rental dengan status idle warning atau idle billing.
- GPS stale / lokasi lama tidak update.
- Heartbeat stale / device tidak mengirim sinyal terbaru.

Sumber aturan waktu:

- `offline_timeout_seconds`
- `gps_update_interval_seconds`

Kegunaan untuk tim:

- Admin bisa tahu sepeda mana yang bermasalah.
- Tim simulator bisa melihat apakah heartbeat jalan.
- Tim backend bisa mengecek aturan offline dan GPS update.

---

### 8. Pengaturan Sistem

URL:

```text
/admin/settings
```

Route:

```text
admin.settings.edit
admin.settings.update
```

File utama:

- `backend/app/Http/Controllers/Admin/SettingController.php`
- `backend/resources/views/admin/settings.blade.php`
- `backend/app/Providers/AppServiceProvider.php`

Hak akses:

```text
superadmin only
```

Kelompok pengaturan:

- Biaya Berdasarkan Jarak.
- Aturan Sepeda Diam.
- Aturan Lokasi.
- Aturan Rental Sepeda.

Contoh setting penting:

- `distance_unit_meters`
- `distance_price_amount`
- `rounding_mode`
- `minimum_billable_distance_meters`
- `max_reasonable_speed_kmh`
- `idle_warning_after_seconds`
- `grace_period_before_idle_billing_seconds`
- `idle_billing_interval_seconds`
- `idle_billing_amount`
- `gps_update_interval_seconds`
- `minimum_movement_threshold_meters`
- `max_gps_accuracy_meters`
- `offline_timeout_seconds`
- `allow_multiple_active_rentals`
- `maximum_rental_duration_minutes`
- `force_finish_when_offline_too_long`

Kegunaan untuk tim:

- Mengubah aturan biaya jarak.
- Mengubah aturan idle warning.
- Mengubah batas akurasi GPS.
- Mengubah timeout offline.
- Mengatur aturan rental tanpa hardcode.

---

## Status dan Label yang Dipakai Admin

Label status dibagikan lewat:

```text
backend/app/Providers/AppServiceProvider.php
```

Status sepeda:

- `available`: tersedia
- `reserved`: dipesan
- `in_use`: sedang dipakai
- `idle`: diam
- `offline`: offline
- `maintenance`: perawatan

Status rental:

- `active`: aktif
- `idle_warning`: peringatan diam
- `idle_billing`: biaya diam berjalan
- `completed`: selesai
- `cancelled`: dibatalkan

Role:

- `user`: pengguna
- `admin`: admin
- `superadmin`: superadmin
- `device`: perangkat sepeda

---

## Data yang Perlu Ada Agar Admin Berguna

Supaya fitur admin terlihat hidup, pastikan data ini ada:

1. Akun admin atau superadmin.
2. Akun device dengan role `device`.
3. Sepeda yang sudah di-assign ke akun device.
4. `mobile_bike` login sebagai akun device.
5. `mobile_bike` mengirim heartbeat.
6. `mobile_bike` mengirim lokasi GPS.
7. User melakukan rental sepeda yang sama.
8. `mobile_user` membuka Active Rental.

Alur data utamanya:

```text
mobile_bike GPS/device
-> backend API
-> bikes.current_latitude/current_longitude
-> rental_location_points
-> admin dashboard map
-> admin monitoring
-> admin rental route map
-> mobile_user Active Rental
```

---

## Testing yang Sudah Disediakan

File test:

- `backend/tests/Feature/AdminMonitoringTest.php`
- `backend/tests/Feature/AdminPagesTest.php`

Yang dicek:

- Guest diarahkan ke admin login.
- Admin bisa membuka monitoring list.
- Admin bisa membuka detail monitoring sepeda.
- Dashboard admin render.
- Dashboard map data mengembalikan JSON.
- Rental aktif render.
- Route map data rental mengembalikan JSON.
- User page render.
- User detail render.
- Report page render.
- Alert page render.
- Superadmin bisa update role user.

Perintah test:

```bash
cd backend
php artisan test --filter=AdminMonitoringTest
php artisan test --filter=AdminPagesTest
```

Atau jalankan semua test backend:

```bash
cd backend
php artisan test
```

---

## Tugas yang Bisa Dikerjakan Teman Setelah Fitur Admin Ini

### Untuk Tim Simulator / Mobile Bike

Manfaatkan admin untuk:

- Cek apakah device sepeda online.
- Cek heartbeat terbaru.
- Cek baterai.
- Cek jenis jaringan.
- Cek lokasi GPS terakhir.
- Cek apakah lokasi Real GPS masuk ke peta admin.

Tugas lanjutan:

- Pastikan `Mode: Real GPS` benar-benar mengirim koordinat dari HP.
- Pastikan titik GPS muncul di `/admin/monitoring-bikes`.
- Pastikan marker sepeda muncul di dashboard admin.
- Pastikan heartbeat tidak stale di menu Peringatan.
- Pastikan battery percent terkirim dan tampil.

### Untuk Tim Active Rental / Mobile User

Manfaatkan admin untuk:

- Cek rental aktif dari sisi admin.
- Cek lokasi terakhir rental.
- Cek rute rental di detail rental.
- Bandingkan data Active Rental dengan data admin.

Tugas lanjutan:

- Cocokkan marker Active Rental dengan marker admin.
- Cocokkan total distance dan total cost.
- Cek apakah route points tetap tersimpan walaupun user menutup screen.
- Cek data idle warning dan idle billing.

### Untuk Tim Rental History

Manfaatkan admin untuk:

- Cek detail rental selesai.
- Cek biaya jarak.
- Cek biaya idle.
- Cek total biaya.
- Cek rute yang tersimpan.

Tugas lanjutan:

- Cocokkan detail history mobile user dengan detail rental admin.
- Pastikan rental selesai muncul di admin dan mobile history.
- Jika ada selisih biaya, cek billing logs di admin rental detail.

### Untuk Tim UI Polish

Manfaatkan admin untuk:

- Melihat label/status resmi yang dipakai backend.
- Menyamakan istilah di mobile user dan mobile bike.
- Menyamakan visual status online/offline/active/completed.

Tugas lanjutan:

- Pastikan istilah di mobile tidak berbeda jauh dari admin.
- Gunakan label Indonesia yang konsisten.

---

## Prompt untuk AI Teman

Gunakan prompt ini jika teman ingin meminta AI mereka melanjutkan fitur berdasarkan admin yang sudah ada:

```text
Saya sedang mengerjakan project Smart Bike Rental.

Di backend Laravel sudah ada Web Admin dari commit:
d34ad01584c7c0ec69b74f20c70f88ef16b9016a

Fitur admin yang sudah tersedia:
- Dashboard admin di /admin
- Peta lokasi sepeda di dashboard dengan Leaflet
- Endpoint JSON /admin/dashboard/map-data
- Monitoring sepeda di /admin/monitoring-bikes
- Detail monitoring sepeda di /admin/monitoring-bikes/{bike}
- Manajemen sepeda di /admin/bikes
- Assign device user ke sepeda
- Rental list di /admin/rentals
- Rental detail di /admin/rentals/{rental}
- Peta rute rental di rental detail
- Endpoint JSON /admin/rentals/{rental}/route-map-data
- Manajemen user di /admin/users
- Detail user di /admin/users/{user}
- Update role user khusus superadmin
- Laporan di /admin/reports
- Peringatan di /admin/alerts
- Pengaturan sistem khusus superadmin di /admin/settings

File penting:
- backend/routes/web.php
- backend/app/Http/Controllers/Admin/DashboardController.php
- backend/app/Http/Controllers/Admin/MonitoringController.php
- backend/app/Http/Controllers/Admin/RentalController.php
- backend/app/Http/Controllers/Admin/UserController.php
- backend/app/Http/Controllers/Admin/AlertController.php
- backend/app/Http/Controllers/Admin/ReportController.php
- backend/app/Http/Controllers/Admin/SettingController.php
- backend/app/Models/Bike.php
- backend/resources/views/layouts/admin.blade.php
- backend/resources/views/admin/dashboard.blade.php
- backend/resources/views/admin/monitoring/index.blade.php
- backend/resources/views/admin/monitoring/show.blade.php
- backend/resources/views/admin/rentals/index.blade.php
- backend/resources/views/admin/rentals/show.blade.php
- backend/resources/views/admin/users/index.blade.php
- backend/resources/views/admin/users/show.blade.php
- backend/resources/views/admin/reports/index.blade.php
- backend/resources/views/admin/alerts/index.blade.php
- backend/resources/views/admin/settings.blade.php

Relasi Bike yang sudah ada:
- assignedDevice()
- rentals()
- activeRental()
- locationPoints()
- latestLocationPoint()
- deviceHeartbeats()
- latestHeartbeat()

Tolong lanjutkan pekerjaan saya tanpa menghapus fitur yang sudah ada.
Ikuti style Blade admin yang sudah ada.
Pastikan route tetap memakai middleware auth dan role admin/superadmin.
Jika menambah fitur baru, tambahkan test Feature Laravel.
Jalankan verifikasi:
php artisan test --filter=AdminMonitoringTest
php artisan test --filter=AdminPagesTest
php artisan route:list

Tujuan saya adalah membuat fitur admin makin berguna untuk monitoring sepeda, GPS, rental aktif, rute rental, peringatan device, dan laporan operasional.
```

---

## Ide Lanjutan yang Masuk Akal

Fitur admin yang bisa dilanjutkan berikutnya:

- Tombol refresh manual di halaman monitoring sepeda.
- Auto refresh tabel monitoring tanpa reload halaman.
- Filter baterai rendah di monitoring.
- Filter sepeda tanpa device assignment.
- Filter sepeda yang GPS-nya stale.
- Export laporan ke CSV.
- Export rental detail ke PDF.
- Detail peta monitoring per sepeda.
- Riwayat heartbeat dengan pagination.
- Riwayat location point dengan pagination.
- Aksi admin untuk set sepeda maintenance.
- Aksi admin untuk force finish rental bermasalah.
- Notifikasi visual untuk sepeda offline terlalu lama.

Prioritas yang paling berguna:

1. Auto refresh monitoring sepeda.
2. Filter sepeda bermasalah.
3. Export laporan.
4. Force finish rental dari admin dengan audit log.
5. Peta detail per sepeda.
