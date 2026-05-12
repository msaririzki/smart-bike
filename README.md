# Smart Bike Rental - Mobile Computing

> Prototipe sistem penyewaan sepeda pintar berbasis **Mobile Computing** — Mata Kuliah Mobile Computing, Universitas Bumigora, Semester 6.

## Tentang Proyek

Sistem ini mensimulasikan penyewaan sepeda pintar dengan smartphone sebagai simulator perangkat IoT pada sepeda. Simulator mengirim GPS dan heartbeat ke backend, lalu backend menghitung jarak, biaya, status idle, dan status online sepeda.

Konsep mobile computing yang ditunjukkan:

- Mobility: sepeda menjadi terminal bergerak.
- Wireless Communication: data dikirim melalui jaringan mobile/Wi-Fi.
- Location Awareness: posisi sepeda dipantau dari GPS.
- Context Awareness: sistem membedakan kondisi bergerak dan idle.
- Dynamic Computing: biaya dihitung dari jarak dan status aktual rental.

## Fitur Utama

- Login dan register user.
- Role `user`, `admin`, `superadmin`, dan `device`.
- Daftar sepeda tersedia.
- Mulai dan selesaikan rental.
- Bike Simulator App untuk GPS stream dan heartbeat.
- Perhitungan jarak menggunakan Haversine formula.
- Distance billing, idle warning, idle billing, dan auto-resume saat bergerak lagi.
- Admin panel untuk dashboard, bike management, rental monitoring, dan pricing settings.
- Live active rental screen di aplikasi user sedang dikerjakan oleh tim.

## Struktur Proyek

```text
smart-bike/
|-- backend/       Laravel 13 API + Admin Panel
|-- mobile_user/   Flutter App untuk pengguna rental
|-- mobile_bike/   Flutter App simulator perangkat sepeda
|-- README.md
```

## Kebutuhan Development

| Software | Versi |
|---|---|
| PHP | >= 8.3 |
| Composer | >= 2.x |
| Node.js | >= 18.x |
| Git | Terbaru |
| Flutter SDK | >= 3.x |
| Android Studio | Terbaru |

## Setup Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Gunakan `--host=0.0.0.0` agar backend bisa diakses dari emulator Android atau HP fisik.

Backend berjalan di:

```text
http://localhost:8000
```

Admin panel:

```text
http://localhost:8000/admin/login
```

## Setup Flutter User App

```bash
cd mobile_user
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Untuk HP fisik, ganti `10.0.2.2` dengan IP laptop, misalnya:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
```

## Setup Flutter Bike Simulator

```bash
cd mobile_bike
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Menjalankan Semua Dev Server

Untuk development cepat dari root project, jalankan:

```bash
npm run dev
```

Script ini menjalankan tiga proses sekaligus:

| Proses | URL / Port |
|---|---|
| Laravel backend | `http://localhost:8000` |
| Flutter User App (Chrome) | `http://localhost:58770` |
| Flutter Bike App (Chrome) | `http://localhost:58771` |

Kedua Flutter app otomatis memakai:

```text
API_BASE_URL=http://127.0.0.1:8000/api
```

Script juga memantau perubahan file `.dart` di `mobile_user/lib` dan `mobile_bike/lib`, lalu mengirim perintah hot reload ke proses Flutter masing-masing.

Untuk override API URL:

```bash
$env:API_BASE_URL="http://192.168.1.5:8000/api"
npm run dev
```

## Akun Demo

| Role | Email | Password |
|---|---|---|
| Superadmin | `superadmin@smartbike.test` | `password` |
| Admin | `admin@smartbike.test` | `password` |
| User | `user@smartbike.test` | `password` |
| Device | `device@smartbike.test` | `password` |

## API Endpoint

### Auth

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/auth/register` | Daftar akun user |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Data user login |

### Bikes

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/bikes` | Daftar sepeda |
| GET | `/api/bikes/{id}` | Detail sepeda |

### Rentals

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/rentals/start` | Mulai sewa |
| GET | `/api/rentals/active` | Rental aktif user, termasuk bike, latest GPS point, dan `current_speed_kmh` |
| GET | `/api/rentals/history` | Histori sewa |
| POST | `/api/rentals/{id}/finish` | Selesaikan sewa |
| POST | `/api/rentals/{id}/idle/continue` | Lanjutkan sewa dari idle warning |

### Device / Simulator

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/device/current-assignment` | Ambil sepeda yang di-assign ke device |
| POST | `/api/device/location-update` | Kirim data GPS |
| POST | `/api/device/heartbeat` | Kirim heartbeat perangkat |

## Sistem Billing

Biaya jarak:

```text
distance_cost = floor(total_distance_meters / distance_unit_meters) * distance_price_amount
```

Default:

| Parameter | Nilai |
|---|---|
| Unit jarak | 100 meter |
| Harga per unit | Rp 500 |
| Threshold gerakan valid | 10 meter |
| Akurasi GPS maksimum | 25 meter |
| Idle warning setelah | 5 menit |
| Interval idle billing | 5 menit |
| Biaya idle | Rp 200 |
| Kecepatan maksimum valid | 40 km/h |

Semua parameter billing dan aturan GPS bisa diubah oleh superadmin melalui admin panel.

## Alur Sistem

```text
User login
  -> pilih sepeda tersedia
  -> mulai sewa, bike status menjadi in_use
  -> simulator mengirim GPS tiap beberapa detik
  -> backend menghitung jarak dan biaya
  -> jika sepeda idle, status berubah ke idle_warning
  -> user bisa lanjut ke idle_billing atau menyelesaikan sewa
  -> rental selesai, bike kembali tersedia
```

## Fase Pengembangan

| Phase | Fitur | Status |
|---|---|---|
| Phase 1 | Auth, roles, bike master, setup backend | Done |
| Phase 2 | Start/finish rental, active rental basic | Done |
| Phase 3 | Bike Simulator App, GPS stream, heartbeat | Done |
| Phase 4 | Haversine, movement validation, distance billing backend | Done |
| Phase 4 | Live active rental screen di user app | In Progress |
| Phase 5 | Idle warning, idle billing, auto resume backend | Done |
| Phase 6 | Superadmin settings UI dan pricing config | Done |
| Phase 7 | Reports, rental history detail, UI polish | Planned |

## Testing Cepat

Backend feature tests:

```bash
cd backend
php artisan test --compact tests/Feature
```

Catatan: full `php artisan test` saat ini membutuhkan perapihan `tests/Unit` atau konfigurasi `phpunit.xml`.

## Teknologi

| Layer | Teknologi |
|---|---|
| Mobile | Flutter, Dart |
| Backend | Laravel 13, PHP 8.3 |
| Auth | Laravel Sanctum |
| Database | SQLite untuk development, MySQL opsional untuk produksi |
| GPS | geolocator |
| Map | OpenStreetMap + flutter_map planned untuk user app |

## Lisensi

Proyek ini dibuat untuk keperluan akademik — Mata Kuliah Mobile Computing, Universitas Bumigora.
