# 🚲 Smart Bike Rental — Mobile Computing

> Prototipe sistem penyewaan sepeda pintar berbasis **Mobile Computing** — Mata Kuliah Mobile Computing, Universitas Bumigora, Semester 6.

---

## 📌 Tentang Proyek

Sistem ini mensimulasikan penyewaan sepeda pintar yang memanfaatkan konsep **mobile computing** secara nyata:

- **Mobility** — Sepeda sebagai terminal bergerak
- **Wireless Communication** — Komunikasi via data seluler
- **Location Awareness** — GPS real-time untuk tracking posisi sepeda
- **Context Awareness** — Sistem membedakan kondisi bergerak dan diam (idle)
- **Dynamic Computing** — Biaya dihitung berdasarkan jarak tempuh aktual

### Fitur Utama
- ✅ Login & Register user
- ✅ Lihat daftar sepeda tersedia
- ✅ Mulai & selesaikan sewa
- 🔄 GPS tracking real-time _(coming soon)_
- 🔄 Perhitungan biaya berbasis jarak — Haversine formula _(coming soon)_
- 🔄 Idle detection & idle billing _(coming soon)_
- 🔄 Admin panel & superadmin settings _(coming soon)_

---

## 🗂️ Struktur Proyek

```
smart-bike-rental/
├── backend/          ← Laravel 12 API + Admin Panel
├── mobile_user/      ← Flutter App (User)
└── README.md
```

---

## 👥 Role di Sistem

| Role | Akses |
|---|---|
| `user` | Login, lihat sepeda, sewa, histori |
| `admin` | Monitor rental, lihat data |
| `superadmin` | Ubah tarif, threshold, semua setting |
| `device` | Simulator sepeda (kirim GPS, heartbeat) |

---

## 💻 Yang Harus Disiapkan di Laptop

### ✅ Wajib untuk semua anggota tim

| Software | Versi | Download |
|---|---|---|
| **PHP** | >= 8.2 | https://www.php.net/downloads |
| **Composer** | >= 2.x | https://getcomposer.org |
| **Node.js** | >= 18.x | https://nodejs.org |
| **Git** | Terbaru | https://git-scm.com |
| **Flutter SDK** | >= 3.x | https://flutter.dev/docs/get-started/install |
| **Android Studio** | Terbaru | https://developer.android.com/studio |
| **VS Code** | Terbaru | https://code.visualstudio.com |

### ✅ Extension VS Code yang disarankan

- **Dart** — `dart-code.dart-code`
- **Flutter** — `dart-code.flutter`
- **PHP Intelephense** — `bmewburn.vscode-intelephense-client`
- **Laravel Blade Snippets** — `onecentlin.laravel-blade`
- **GitLens** — `eamodio.gitlens`

### ✅ Cek instalasi di terminal

```bash
php --version        # Harus >= 8.2
composer --version   # Harus >= 2.x
flutter --version    # Harus >= 3.x
node --version       # Harus >= 18.x
git --version
```

---

## 🚀 Setup Proyek (Pertama Kali)

### 1. Clone Repository

```bash
git clone https://github.com/msaririzki/smart-bike.git
cd smart-bike-rental
```

### 2. Setup Backend (Laravel)

```bash
cd backend

# Install dependencies
composer install

# Salin file environment
cp .env.example .env

# Generate app key
php artisan key:generate

# Jalankan migrasi & seeder (isi data demo)
php artisan migrate:fresh --seed

# Jalankan server
php artisan serve --host=0.0.0.0 --port=8000
```

> ⚠️ **Penting:** Gunakan `--host=0.0.0.0` agar bisa diakses dari emulator Android

Backend akan jalan di: `http://localhost:8000`

### 3. Setup Flutter App (mobile_user)

Buka terminal baru:

```bash
cd mobile_user

# Install dependencies Flutter
flutter pub get
```

### 4. Jalankan Flutter App

#### Untuk Android Emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

#### Untuk HP Fisik (sambungkan HP via USB):
Cari IP laptop terlebih dulu:
```bash
# Windows
ipconfig
# Cari "IPv4 Address" di bagian Wi-Fi, contoh: 192.168.1.5
```
Lalu jalankan:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
```

> 💡 HP dan laptop harus tersambung ke **Wi-Fi yang sama**

---

## 🔐 Akun Demo (Sudah Ada Setelah Seed)

| Role | Email | Password |
|---|---|---|
| **Superadmin** | `superadmin@smartbike.test` | `password` |
| **Admin** | `admin@smartbike.test` | `password` |
| **User** | `user@smartbike.test` | `password` |

### Akses Admin Panel (di browser):
```
http://localhost:8000/admin/login
```

### Akses API:
```
http://localhost:8000/api
```

---

## 📡 Daftar API Endpoint

### Auth
| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/auth/register` | Daftar akun baru |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Data user login |

### Bikes
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/bikes` | Daftar sepeda tersedia |
| GET | `/api/bikes/{id}` | Detail sepeda |

### Rentals
| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/rentals/start` | Mulai sewa |
| GET | `/api/rentals/active` | Rental aktif user |
| POST | `/api/rentals/{id}/finish` | Selesaikan sewa |
| GET | `/api/rentals/history` | Histori sewa |

### Device / Simulator _(coming soon)_
| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/api/device/location-update` | Kirim data GPS |
| POST | `/api/device/heartbeat` | Heartbeat perangkat |

---

## ⚙️ Sistem Billing

### Biaya Jarak
```
biaya_jarak = floor(total_jarak_meter / unit_meter) × harga_per_unit
```
Contoh:
- Jarak: 550 meter
- Unit: 100 meter → Rp 500
- Hasil: floor(550/100) × 500 = **Rp 2.500**

### Biaya Idle
Jika sepeda diam > 5 menit:
- Muncul **peringatan idle**
- Jika user pilih lanjut → kena biaya idle **Rp 200 / 5 menit**

### Default Parameter
| Parameter | Nilai Default |
|---|---|
| Unit jarak | 100 meter |
| Harga per unit | Rp 500 |
| Threshold gerakan valid | 10 meter |
| Akurasi GPS max | 25 meter |
| Idle warning setelah | 5 menit |
| Interval idle billing | 5 menit |
| Biaya idle | Rp 200 |
| Kecepatan max valid | 40 km/h |

> Semua parameter di atas bisa diubah oleh **Superadmin** melalui admin panel

---

## 🔄 Alur Kerja Sistem

```
User Login
    ↓
Pilih Sepeda Tersedia
    ↓
Mulai Sewa → Bike status: in_use
    ↓
Bike Simulator kirim GPS tiap 5 detik
    ↓
Server hitung jarak (Haversine) → Update biaya
    ↓
Jika diam > 5 menit → Idle Warning
    ↓
User pilih: Lanjut (idle billing) / Selesai
    ↓
Selesai Sewa → Tampil ringkasan biaya
```

---

## 🐛 Troubleshooting

### ❌ Flutter tidak bisa konek ke backend di emulator
- Pastikan backend jalan dengan `--host=0.0.0.0`
- Pastikan Flutter dijalankan dengan `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api`

### ❌ `php artisan serve` tidak bisa diakses dari HP fisik
- Gunakan `--host=0.0.0.0`
- Cek firewall Windows — izinkan port 8000
- HP dan laptop harus di jaringan Wi-Fi yang sama

### ❌ Error `SQLSTATE` saat migrate
- Pastikan file `.env` sudah ada (copy dari `.env.example`)
- Jalankan `php artisan key:generate`

### ❌ `flutter pub get` gagal
- Pastikan Flutter SDK sudah terinstall: `flutter doctor`
- Pastikan koneksi internet aktif

### ❌ Emulator tidak muncul di `flutter run`
- Buka Android Studio → Device Manager → Start emulator
- Atau jalankan `flutter devices` untuk cek device tersedia

---

## 📋 Fase Pengembangan

| Phase | Fitur | Status |
|---|---|---|
| **Phase 1** | Auth, roles, bike master, setup backend | ✅ Done |
| **Phase 2** | Start/finish rental, active rental view | ✅ Done |
| **Phase 3** | Bike Simulator App, GPS stream, live map | 🔄 Planned |
| **Phase 4** | Haversine, movement validation, distance billing | 🔄 Planned |
| **Phase 5** | Idle warning, idle billing, auto resume | 🔄 Planned |
| **Phase 6** | Superadmin settings UI, pricing config | 🔄 Planned |
| **Phase 7** | Reports, billing logs, UI polish | 🔄 Planned |

---

## 👨‍💻 Tim Pengembang

| Nama | GitHub | Peran |
|---|---|---|
| M. Sari Rizki | [@msaririzki](https://github.com/msaririzki) | Project Lead / Backend / Mobile |

---

## 📚 Teknologi yang Digunakan

| Layer | Teknologi |
|---|---|
| Mobile | Flutter (Dart) |
| Backend | Laravel 12, PHP 8.2 |
| Auth | Laravel Sanctum |
| Database | SQLite (dev) / MySQL (prod) |
| Map | OpenStreetMap + flutter_map _(planned)_ |
| GPS | geolocator _(planned)_ |
| Real-time | Laravel Reverb / Pusher _(planned)_ |

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik — Mata Kuliah Mobile Computing, Universitas Bumigora.
