# Dokumentasi Update Mobile Bike Dashboard

Tanggal: 12 Mei 2026  
Area: `mobile_bike` dan backend device API  
Status: siap diuji setelah merge ke `main`

---

## Ringkasan Update

`mobile_bike` sekarang diarahkan menjadi dashboard perangkat sepeda, bukan hanya simulator input lokasi.

Prinsip alur data:

```text
GPS HP/device
-> mobile_bike
-> backend
-> data rental, lokasi, biaya, dan rute diolah backend
-> mobile_user dan admin menampilkan hasilnya
```

`mobile_user` tidak mengambil GPS sepeda. Map di `mobile_user` hanya menampilkan data lokasi yang dikirim oleh `mobile_bike` melalui backend.

---

## Backend Device API Baru

Endpoint baru:

```text
GET /api/device/active-rental-summary
```

File:

```text
backend/app/Http/Controllers/Api/DeviceController.php
backend/routes/api.php
```

Fungsi endpoint:

- mencari sepeda yang di-assign ke akun device yang sedang login
- mengambil rental aktif dari sepeda tersebut
- mengembalikan ringkasan sepeda dan rental aktif

Data yang dikirim:

- data sepeda:
  - id
  - code
  - name
  - status
  - is_online
  - battery_percent
  - current_latitude
  - current_longitude
  - last_accuracy
  - last_seen_at
  - network_type
- data rental aktif:
  - id
  - status
  - started_at
  - total_distance_meters
  - distance_cost
  - idle_cost
  - total_cost
  - current_speed_kmh
  - user
  - latest_location_point

Jika device belum di-assign ke sepeda, response tetap aman:

```json
{
  "data": {
    "bike": null,
    "rental": null
  }
}
```

---

## Update Mobile Bike

File utama:

```text
mobile_bike/lib/src/features/simulator/simulator_screen.dart
mobile_bike/lib/src/features/simulator/manual_gps_panel.dart
mobile_bike/lib/src/models/device_rental_summary.dart
mobile_bike/lib/src/services/api_client.dart
mobile_bike/lib/src/services/gps_service.dart
```

### 1. Dashboard Sepeda

Judul layar sekarang:

```text
Dashboard Sepeda
```

Dashboard menampilkan:

- status pengiriman GPS
- mode lokasi
- status server terakhir
- kode dan nama sepeda
- status sepeda
- kecepatan real-time
- kualitas GPS
- koordinat terbaru
- waktu terakhir kirim
- mini route map
- ringkasan rental aktif
- baterai
- jaringan
- jumlah titik terkirim
- mode lokasi
- status device

---

### 2. Kecepatan Real-Time dan Mini Route Map

Panel kecepatan sekarang memiliki:

- angka speed besar dalam `km/h`
- progress visual speed
- mini route map lokal
- titik awal
- titik terbaru
- garis jalur yang sudah dilewati
- jumlah titik GPS
- estimasi akurasi GPS

Mini route map memakai `CustomPainter`, bukan tile map. Jadi:

- ringan
- tidak butuh internet
- cocok untuk dashboard device
- menampilkan jalur relatif dari titik yang dikirim device

Catatan:

Mini route map di `mobile_bike` adalah visual lokal agar penguji melihat pergerakan device. Sumber kebenaran data tetap backend.

---

### 3. Ringkasan Rental Aktif

Jika sepeda sedang dirental, dashboard menampilkan:

- penyewa
- status rental
- durasi
- total jarak
- biaya jarak
- biaya idle
- total biaya

Biaya sekarang dibuat ringkas satu baris:

```text
Jarak | Idle | Total
```

Tujuannya agar tidak memakan banyak tempat dan lebih mudah dibaca saat device dipasang di sepeda.

Jika belum ada rental aktif, dashboard menampilkan pesan bahwa device tetap bisa mengirim lokasi dan heartbeat untuk monitoring admin.

---

### 4. GPS Real Sebagai Jalur Utama

Tombol utama:

```text
Mulai Kirim GPS Real
```

Saat tombol ini ditekan:

- app meminta permission lokasi
- app membaca GPS dari HP/device
- app mengirim latitude, longitude, speed, accuracy, dan network type ke backend
- app mengirim heartbeat berkala
- dashboard menampilkan speed dan jalur

Manual GPS dan Mock Route bukan jalur utama. Keduanya hanya untuk debug/demo.

---

### 5. Filter Akurasi GPS

`GpsService` sekarang memakai:

```text
LocationAccuracy.bestForNavigation
distanceFilter: 1 meter
```

Dashboard juga menolak titik GPS real yang:

- akurasinya lebih buruk dari 50 meter
- terlihat seperti loncatan tidak wajar
- bergerak terlalu kecil sehingga kemungkinan noise

Tujuan:

- jalur tidak terlihat loncat-loncat
- titik yang dikirim lebih stabil
- visual route lebih nyaman dilihat

Catatan:

Akurasi tetap bergantung pada HP, lokasi testing, cuaca, gedung, dan permission. Aplikasi sudah meminta akurasi tinggi, tetapi hardware tetap menentukan hasil akhir.

---

### 6. Panel Kontrol Debug

Panel kontrol debug sekarang selalu terlihat, tidak disembunyikan di dropdown.

Isi panel:

- preset lokasi
- input latitude/longitude manual
- tombol kirim koordinat manual
- interval mock route
- mode mock route
- switch simulasi pergerakan otomatis

Pesan penting di UI:

```text
Untuk penggunaan nyata, tetap gunakan tombol Mulai Kirim GPS Real.
```

---

## Cara Testing End-to-End

### 1. Jalankan Backend

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

### 2. Jalankan Mobile Bike di HP

```bash
cd mobile_bike
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

### 3. Jalankan Mobile User

```bash
cd mobile_user
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

### 4. Alur Test

1. Login `mobile_bike` sebagai akun device.
2. Pastikan device sudah di-assign ke sepeda di admin.
3. Login `mobile_user` sebagai user.
4. User mulai rental sepeda yang sama.
5. Di `mobile_bike`, tekan `Mulai Kirim GPS Real`.
6. Izinkan permission lokasi.
7. Bawa HP/device berjalan.
8. Cek dashboard `mobile_bike`:
   - speed berubah
   - GPS quality muncul
   - mini route map membentuk jalur
   - titik terkirim bertambah
   - durasi rental berjalan
   - biaya dan jarak bertambah setelah backend memproses pergerakan valid
9. Cek `mobile_user`:
   - map mengikuti data dari `mobile_bike`
   - total jarak dan biaya sesuai backend
10. Cek admin:
   - dashboard map menampilkan sepeda
   - monitoring sepeda menampilkan lokasi dan heartbeat
   - detail rental menampilkan rute

---

## Verifikasi Teknis

Perintah yang sudah digunakan:

```bash
cd backend
php -l app/Http/Controllers/Api/DeviceController.php
php artisan route:list --path=api/device
php artisan test
```

```bash
cd mobile_bike
dart format lib/src/models/device_rental_summary.dart lib/src/services/api_client.dart lib/src/services/gps_service.dart lib/src/features/simulator/simulator_screen.dart lib/src/features/simulator/manual_gps_panel.dart
flutter analyze
flutter test
```

---

## Catatan untuk Tim

Yang harus diingat:

- GPS sepeda berasal dari `mobile_bike`.
- `mobile_user` hanya viewer data rental/lokasi dari backend.
- `mobile_bike` adalah dashboard device yang mengirim data.
- Backend adalah sumber ringkasan jarak, biaya, rental aktif, dan rute tersimpan.
- Panel manual/mock hanya debug, bukan jalur nyata.
