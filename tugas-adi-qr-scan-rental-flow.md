# Tugas Adi Saputra - QR Scan Rental Flow

Nama: Adi Saputra  
NIM: 2301010016  
Branch kerja yang disarankan: `feature/qr-scan-rental-flow`

## Ringkasan

Saat ini user bisa menyewa sepeda dari daftar sepeda di `mobile_user` hanya dengan menekan tombol sewa. Alur ini kurang realistis karena user bisa memulai sewa dari jarak jauh tanpa benar-benar berada di dekat sepeda.

Tugas Adi berikutnya adalah membuat alur rental lebih nyata:

> User harus scan QR yang ada di sepeda atau ditampilkan oleh aplikasi `mobile_bike`, baru rental bisa dimulai.

Dengan fitur ini, `mobile_user` tidak langsung menyewa sepeda dari list. List sepeda hanya untuk melihat ketersediaan. Untuk mulai sewa, user harus mendekati sepeda dan scan QR.

## Tujuan Fitur

1. Membuat flow rental lebih realistis.
2. Mencegah user menyewa sepeda dari jarak jauh.
3. Menghubungkan `mobile_user`, `mobile_bike`, dan backend dalam satu flow yang jelas.
4. Membuat demo lebih kuat karena rental dimulai dari interaksi fisik dengan sepeda.
5. Menyiapkan dasar untuk sistem rental berbasis device seperti produk nyata.

## Konsep Utama

Ada dua pilihan QR:

1. **QR statis di sepeda**
   - QR ditempel secara fisik di sepeda.
   - Isi QR mengarah ke kode sepeda atau token permanen.
   - Lebih mudah untuk demo, tapi kurang aman.

2. **QR dinamis dari aplikasi `mobile_bike`**
   - QR ditampilkan di layar perangkat `mobile_bike`.
   - Token QR dibuat oleh backend.
   - Token punya masa berlaku pendek.
   - Lebih aman dan lebih realistis karena membuktikan perangkat sepeda sedang online.

Untuk project ini, rekomendasi utama adalah **QR dinamis dari `mobile_bike`**. QR statis boleh dibuat sebagai fallback jika perangkat sepeda belum siap menampilkan QR.

## Alur Yang Diinginkan

### Flow Dari Sisi User

1. User login di `mobile_user`.
2. User membuka Home.
3. User melihat daftar sepeda dan statusnya.
4. Tombol utama di Home bukan lagi langsung `Sewa Sekarang`, tetapi:
   - `Scan QR Sepeda`
5. User menekan `Scan QR Sepeda`.
6. Kamera terbuka.
7. User scan QR yang ada di `mobile_bike` atau QR fisik di sepeda.
8. `mobile_user` mengirim token QR ke backend.
9. Backend memvalidasi QR.
10. Jika valid, backend memulai rental.
11. User diarahkan ke Active Rental Screen.
12. Jika QR tidak valid, expired, atau sepeda tidak tersedia, tampilkan pesan error yang jelas.

### Flow Dari Sisi Mobile Bike

1. Device login sebagai role `device`.
2. `mobile_bike` mengambil assignment sepeda dari backend.
3. Jika device sudah terhubung ke sepeda, `mobile_bike` meminta QR rental session ke backend.
4. Backend mengembalikan token QR dengan masa berlaku.
5. `mobile_bike` menampilkan QR di dashboard.
6. QR otomatis refresh sebelum expired.
7. Jika rental aktif, QR disembunyikan atau diganti dengan status:
   - `Sedang Disewa`
8. Jika device offline atau belum assign sepeda, QR tidak ditampilkan.

### Flow Dari Sisi Backend

1. Backend membuat token QR untuk sepeda yang valid.
2. Token QR disimpan di database.
3. Token punya expiry time, misalnya 60 detik.
4. Saat user scan QR, backend cek:
   - token ada
   - token belum expired
   - token belum dipakai
   - sepeda tersedia
   - device masih assign ke sepeda
   - user belum punya rental aktif
5. Jika valid, backend membuat rental.
6. Token ditandai sudah dipakai agar tidak bisa dipakai ulang.

## Rekomendasi Arsitektur

## Backend

### 1. Buat Tabel `bike_qr_sessions`

Migration baru:

```text
backend/database/migrations/xxxx_xx_xx_xxxxxx_create_bike_qr_sessions_table.php
```

Field yang disarankan:

```text
id
bike_id
device_user_id
token
expires_at
used_at
used_by_user_id
created_at
updated_at
```

Catatan:
- `token` harus unik.
- `expires_at` wajib ada.
- `used_at` null berarti token belum dipakai.
- `used_by_user_id` null sampai token dipakai user.

### 2. Buat Model `BikeQrSession`

File:

```text
backend/app/Models/BikeQrSession.php
```

Relasi:

```php
public function bike()
public function deviceUser()
public function usedByUser()
```

### 3. Endpoint Untuk Mobile Bike Membuat QR

Route:

```text
POST /api/device/rental-qr
```

Middleware:

```text
auth:sanctum
role:device
```

Controller:

```text
backend/app/Http/Controllers/Api/DeviceController.php
```

Response contoh:

```json
{
  "data": {
    "token": "qr_xxxxxxxxx",
    "payload": "smartbike://rent?token=qr_xxxxxxxxx",
    "expires_at": "2026-05-12T12:00:00+08:00",
    "bike": {
      "id": 1,
      "code": "BIKE-001",
      "name": "Sepeda 1"
    }
  }
}
```

Catatan:
- `payload` adalah string yang akan dijadikan QR.
- Untuk demo, QR bisa berisi `smartbike://rent?token=...`.
- Jika scanner hanya membaca string biasa, `mobile_user` cukup parse token dari payload.

### 4. Endpoint Untuk User Mulai Rental Dari QR

Route:

```text
POST /api/rentals/start-from-qr
```

Body:

```json
{
  "token": "qr_xxxxxxxxx"
}
```

Validasi:
- token wajib.
- token harus ada di `bike_qr_sessions`.
- `expires_at` harus lebih besar dari waktu sekarang.
- `used_at` harus null.
- bike harus `available`.
- bike tidak sedang punya rental aktif.
- user tidak sedang punya rental aktif, kecuali setting backend mengizinkan.

Response sukses:

```json
{
  "data": {
    "id": 10,
    "status": "active",
    "bike": {
      "id": 1,
      "code": "BIKE-001",
      "name": "Sepeda 1"
    }
  }
}
```

### 5. Service Backend

Tambahkan service baru:

```text
backend/app/Services/BikeQrRentalService.php
```

Tanggung jawab:
- generate token QR
- hapus atau expire token lama
- validasi token
- mulai rental dari QR
- tandai token sebagai used

Kenapa perlu service?

Supaya logic tidak menumpuk di controller dan lebih mudah dites.

## Mobile Bike

### 1. Tambahkan Dependency QR Generator

Di `mobile_bike/pubspec.yaml`:

```yaml
qr_flutter: ^4.1.0
```

Catatan:
- Jalankan `flutter pub get`.
- Pastikan `flutter analyze` tetap lolos.

### 2. Tambahkan Method API Client

File:

```text
mobile_bike/lib/src/services/api_client.dart
```

Method:

```dart
Future<RentalQrSession> createRentalQr()
```

Buat model:

```text
mobile_bike/lib/src/models/rental_qr_session.dart
```

Field:

```dart
token
payload
expiresAt
bike
```

### 3. Tampilkan QR Di Dashboard Mobile Bike

File utama:

```text
mobile_bike/lib/src/features/simulator/simulator_screen.dart
```

Tambahkan panel:

```text
QR Sewa Sepeda
```

Isi panel:
- QR code.
- kode sepeda.
- nama sepeda.
- countdown expired.
- tombol refresh QR.
- status:
  - `QR aktif`
  - `QR expired`
  - `Tidak bisa membuat QR`
  - `Sepeda sedang disewa`

Aturan UI:
- Jika tidak ada assignment sepeda, QR tidak muncul.
- Jika rental aktif, QR tidak muncul.
- Jika device offline atau request gagal, tampilkan error state.
- QR refresh otomatis setiap 45 detik jika expiry 60 detik.

## Mobile User

### 1. Tambahkan Dependency Scanner

Di `mobile_user/pubspec.yaml`:

```yaml
mobile_scanner: ^6.0.2
```

Catatan:
- Tambahkan permission kamera Android jika belum ada.
- Jalankan `flutter pub get`.

### 2. Tambahkan Permission Kamera

File:

```text
mobile_user/android/app/src/main/AndroidManifest.xml
```

Tambahkan:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 3. Buat Screen Scanner

File baru:

```text
mobile_user/lib/src/features/rental/qr_scan_screen.dart
```

Fitur:
- membuka kamera.
- scan QR.
- parse token.
- kirim token ke backend.
- loading state saat request start rental.
- error state jika QR invalid.
- tombol manual retry.
- tombol kembali.

UI yang diharapkan:
- Frame scanner jelas.
- Teks pendek:
  - `Arahkan kamera ke QR di sepeda`
- Jangan terlalu banyak instruksi panjang.
- Jika berhasil, otomatis masuk Active Rental.

### 4. Update API Client Mobile User

File:

```text
mobile_user/lib/src/services/api_client.dart
```

Tambahkan:

```dart
Future<Rental> startRentalFromQr(String token)
```

Endpoint:

```text
POST /rentals/start-from-qr
```

### 5. Update Home Screen

File:

```text
mobile_user/lib/src/features/home/home_screen.dart
```

Perubahan:
- Tombol global di atas atau bawah:
  - `Scan QR Sepeda`
- Kartu sepeda tidak lagi menjadi jalan utama untuk start rental jarak jauh.
- Tombol `Sewa Sekarang` di card sepeda sebaiknya diganti menjadi:
  - `Lihat Detail`
  - atau `Scan QR untuk Sewa`

Rekomendasi flow:
- Home tetap menampilkan daftar sepeda untuk monitoring ketersediaan.
- Aksi utama untuk mulai sewa hanya lewat scanner.

## Format Payload QR

Gunakan format:

```text
smartbike://rent?token=qr_xxxxxxxxx
```

Parser di `mobile_user` harus bisa membaca:

1. Format lengkap:

```text
smartbike://rent?token=qr_xxxxxxxxx
```

2. Format token langsung:

```text
qr_xxxxxxxxx
```

Tujuannya agar testing lebih mudah.

## Error Message Yang Harus Ditangani

### QR Expired

Pesan:

```text
QR sudah kedaluwarsa. Minta QR baru dari perangkat sepeda.
```

### Sepeda Sedang Disewa

Pesan:

```text
Sepeda ini sedang disewa.
```

### Sepeda Tidak Tersedia

Pesan:

```text
Sepeda belum tersedia untuk disewa.
```

### User Sudah Punya Rental Aktif

Pesan:

```text
Selesaikan rental aktif sebelum menyewa sepeda lain.
```

### QR Tidak Valid

Pesan:

```text
QR tidak valid untuk Smart Bike.
```

### Koneksi Gagal

Pesan:

```text
Gagal menghubungi server. Periksa koneksi internet.
```

## Security Rules

Fitur ini harus mengikuti aturan berikut:

1. Token QR tidak boleh mudah ditebak.
2. Token QR harus expired.
3. Token QR hanya bisa dipakai satu kali.
4. Token QR hanya dibuat oleh device user yang punya sepeda assigned.
5. Token QR tidak boleh bisa dipakai jika sepeda sedang disewa.
6. Token QR tidak boleh bisa dipakai oleh user yang sedang punya rental aktif.
7. Endpoint start dari QR harus tetap memakai auth user.
8. Jangan mengirim `bike_id` dari QR lalu langsung start rental tanpa validasi token.

## Testing Backend

Tambahkan test di:

```text
backend/tests/Feature/QrRentalFlowTest.php
```

Minimal test:

1. Device bisa membuat QR jika punya assigned bike.
2. Device tidak bisa membuat QR jika tidak punya assigned bike.
3. User bisa start rental dari QR valid.
4. QR tidak bisa dipakai dua kali.
5. QR expired tidak bisa dipakai.
6. User tidak bisa start QR jika sudah punya rental aktif.
7. QR untuk bike yang tidak available ditolak.
8. Role selain device tidak bisa generate QR.
9. Guest tidak bisa start rental dari QR.

## Testing Mobile

### Mobile Bike

Checklist:

- Login sebagai device.
- Pastikan device punya assigned bike.
- QR tampil.
- Countdown expiry berjalan.
- QR refresh otomatis.
- Saat rental aktif, QR tidak ditampilkan.
- Jika request QR gagal, error state muncul.

### Mobile User

Checklist:

- Login sebagai user.
- Tekan `Scan QR Sepeda`.
- Kamera terbuka.
- Scan QR dari `mobile_bike`.
- Rental berhasil dibuat.
- User masuk Active Rental.
- Scan QR expired harus gagal.
- Scan QR yang sama dua kali harus gagal.
- Jika user punya rental aktif, scan QR baru harus gagal.

## Acceptance Criteria

Fitur dianggap selesai jika:

- `mobile_bike` bisa menampilkan QR rental.
- `mobile_user` bisa scan QR.
- Rental hanya bisa dimulai dari QR valid.
- Start rental dari jarak jauh lewat tombol list sudah tidak menjadi flow utama.
- Backend punya validasi token QR.
- Token expired dan one-time use.
- Test backend untuk QR flow lolos.
- `flutter analyze` lolos untuk `mobile_user`.
- `flutter analyze` lolos untuk `mobile_bike`.
- `php artisan test tests/Feature` lolos.

## Urutan Kerja Yang Disarankan

### Tahap 1 - Backend

1. Buat migration `bike_qr_sessions`.
2. Buat model `BikeQrSession`.
3. Buat service `BikeQrRentalService`.
4. Buat endpoint generate QR untuk device.
5. Buat endpoint start rental dari QR untuk user.
6. Tambahkan feature test.

### Tahap 2 - Mobile Bike

1. Tambahkan dependency `qr_flutter`.
2. Buat model QR session.
3. Tambahkan method API.
4. Buat panel QR di dashboard.
5. Tambahkan countdown dan refresh.

### Tahap 3 - Mobile User

1. Tambahkan dependency `mobile_scanner`.
2. Tambahkan permission kamera.
3. Buat `QrScanScreen`.
4. Tambahkan method `startRentalFromQr`.
5. Update Home agar start rental lewat scan QR.

### Tahap 4 - Integrasi dan Testing

1. Jalankan backend.
2. Login `mobile_bike` sebagai device.
3. Tampilkan QR.
4. Login `mobile_user` sebagai user.
5. Scan QR.
6. Pastikan Active Rental terbuka.
7. Pastikan QR yang sama tidak bisa dipakai lagi.

## Risiko Yang Harus Diperhatikan

### Kamera Tidak Jalan Di Emulator

Solusi:
- Test di HP fisik lebih baik.
- Untuk fallback development, sediakan input manual token di screen scanner dengan mode debug.

### QR Expired Terlalu Cepat

Solusi:
- Untuk demo, expiry bisa 120 detik.
- Untuk mode real, expiry 60 detik cukup.

### Mobile Bike Belum Online

Solusi:
- QR hanya tampil jika device berhasil ambil assignment dan heartbeat berjalan.

### Dependency Scanner Bermasalah

Solusi:
- Pakai `mobile_scanner` karena populer dan cukup stabil.
- Jika ada masalah build, jangan ganti banyak package tanpa diskusi.

## Hal Yang Tidak Perlu Dikerjakan Dulu

Jangan dulu mengerjakan:

- pembayaran online asli
- deep link otomatis dari QR
- NFC
- QR fisik permanen sebagai sistem utama
- websocket
- admin print QR

Fokus dulu sampai rental bisa dimulai dari QR dinamis.

## Prompt Untuk AI Adi

Adi bisa memakai prompt berikut:

```text
Saya mengerjakan project Smart Bike Rental pada branch feature/qr-scan-rental-flow.

Tolong bantu implementasi fitur QR Scan Rental Flow.

Kondisi sekarang:
- mobile_user masih bisa start rental dari daftar sepeda menggunakan bike_id.
- mobile_bike adalah aplikasi device sepeda.
- backend Laravel sudah punya endpoint start rental biasa di POST /api/rentals/start.
- Saya ingin user hanya bisa mulai sewa setelah scan QR dari sepeda/mobile_bike.

Target:
1. Backend membuat QR session untuk device sepeda.
2. mobile_bike menampilkan QR dinamis.
3. mobile_user scan QR dan start rental dari token QR.
4. Token QR harus expired dan one-time use.
5. Jangan merusak flow active rental, live map, idle warning, dan rental history.

Tolong kerjakan bertahap:
1. Cek struktur backend, mobile_user, dan mobile_bike.
2. Buat migration bike_qr_sessions.
3. Buat model dan service QR rental.
4. Tambahkan endpoint device generate QR.
5. Tambahkan endpoint user start rental dari QR.
6. Tambahkan test backend.
7. Tambahkan QR display di mobile_bike.
8. Tambahkan scanner di mobile_user.
9. Update Home supaya scan QR menjadi flow utama.
10. Jalankan php artisan test tests/Feature, flutter analyze, dan flutter test.

Jangan gunakan git reset --hard.
Jangan hapus fitur orang lain.
Jika ada conflict, jelaskan file mana yang conflict dan gabungkan dengan aman.
```

## Output Yang Harus Dilaporkan Adi

Saat selesai, Adi harus melaporkan:

- Screenshot QR tampil di `mobile_bike`.
- Screenshot scanner di `mobile_user`.
- Screenshot Active Rental setelah scan berhasil.
- Bukti QR expired ditolak.
- Bukti QR yang sama tidak bisa dipakai dua kali.
- Hasil `php artisan test tests/Feature`.
- Hasil `flutter analyze` untuk `mobile_user`.
- Hasil `flutter analyze` untuk `mobile_bike`.
- Commit hash terakhir di branch.

