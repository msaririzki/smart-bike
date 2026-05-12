# 📋 Pembagian Tugas Tim — Smart Bike Rental

**Mata Kuliah:** Mobile Computing — Universitas Bina Bangsa
**Repo:** https://github.com/msaririzki/smart-bike
**Project Lead:** M. Sari Rizki (msaririzki)

---

## ✅ Yang Sudah Selesai (oleh Project Lead)

| Phase | Fitur | Status |
|---|---|---|
| Phase 1 | Auth, roles, backend Laravel, seeder | ✅ Done |
| Phase 2 | Start/finish rental, active rental basic | ✅ Done |
| Phase 3 | Bike Simulator App (GPS stream, heartbeat) | ✅ Done |

---

## 👥 Pembagian Tugas

---

### 🔵 Anggota 1 — I Made Riki Widiastana Sanjaya (2301010051)
**Phase 4 — Live Active Rental Screen (User App)**

**Tugas:** Update halaman rental aktif di `mobile_user` agar menampilkan data real-time dari server: jarak tempuh, kecepatan, biaya jarak, dan biaya idle yang terus update.

**File yang dikerjakan:**
```
mobile_user/lib/src/features/home/home_screen.dart   ← tambah navigasi ke rental aktif
mobile_user/lib/src/features/rental/                 ← folder baru
    active_rental_screen.dart                         ← screen utama [BUAT BARU]
```

**Yang harus ditampilkan di `active_rental_screen.dart`:**
- Status rental (badge: ACTIVE / IDLE WARNING / IDLE BILLING)
- Nama & kode sepeda
- Total jarak tempuh (meter → km)
- Kecepatan terkini (km/h)
- Biaya jarak (Rp)
- Biaya idle (Rp)
- Total biaya (Rp)
- Durasi sewa (timer berjalan)
- Tombol **Selesaikan Sewa**
- Auto-refresh data setiap 5 detik (gunakan `Timer.periodic`)

**Endpoint yang dipakai:**
```
GET /api/rentals/active
Response: { data: { id, status, total_distance_meters, distance_cost, idle_cost, total_cost, bike: {...} } }
```

**Tambahkan method ke `api_client.dart`:**
```dart
Future<Map<String, dynamic>?> activeRentalDetail() async { ... }
```

**Cara test:**
1. Jalankan backend: `php artisan serve --host=0.0.0.0 --port=8000`
2. Jalankan mobile_user dengan emulator
3. Login → pilih sepeda → mulai sewa
4. Pastikan data tampil dan refresh otomatis

---

### 🟢 Anggota 2 — Made Arya Sutha Wijaya (2301010030)
**Phase 4 — Live Map (User App)**

**Tugas:** Tambahkan tampilan peta OpenStreetMap di halaman rental aktif yang menampilkan posisi sepeda secara real-time.

**Tambahkan dependency ke `mobile_user/pubspec.yaml`:**
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

**File yang dikerjakan:**
```
mobile_user/lib/src/features/rental/
    map_widget.dart      ← widget peta [BUAT BARU]
    (integrasi ke active_rental_screen.dart milik Riki)
```

**Yang harus ada di peta:**
- Tile OpenStreetMap (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`)
- Marker posisi sepeda (update tiap refresh)
- Polyline rute perjalanan (titik-titik GPS yang sudah dilewati)
- Center otomatis ke posisi sepeda terbaru

**Endpoint yang dipakai:**
```
GET /api/rentals/active
→ bike.current_latitude, bike.current_longitude
```

**Contoh kode MapWidget:**
```dart
FlutterMap(
  options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 16),
  children: [
    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    MarkerLayer(markers: [ Marker(...) ]),
    PolylineLayer(polylines: [ Polyline(points: routePoints, color: Colors.blue) ]),
  ],
)
```

**Cara test:**
1. Jalankan mobile_bike simulator → aktifkan GPS stream
2. Buka mobile_user → lihat posisi sepeda bergerak di peta

---

### 🟡 Anggota 3 — Adi Saputra (2301010016)
**Phase 5 — Idle Warning & Idle Billing UI (User App)**

**Tugas:** Tambahkan logika dan tampilan peringatan idle di mobile_user. Ketika status rental berubah ke `idle_warning`, tampilkan modal dialog kepada user.

**File yang dikerjakan:**
```
mobile_user/lib/src/features/rental/
    idle_warning_dialog.dart    ← dialog peringatan [BUAT BARU]
    (integrasi ke active_rental_screen.dart)
```

**Logika yang harus diimplementasikan:**
1. Saat polling `/api/rentals/active`, cek `data.status`
2. Jika status = `idle_warning` → tampilkan `IdleWarningDialog`
3. Dialog berisi:
   - Pesan: *"Sepeda tidak bergerak selama 5 menit"*
   - Tombol **Lanjutkan Sewa** → POST `/api/rentals/{id}/idle/continue`
   - Tombol **Selesaikan Sewa** → POST `/api/rentals/{id}/finish`
4. Jika status = `idle_billing` → tampilkan badge oranye "IDLE BILLING" + biaya idle berjalan
5. Jika status kembali `active` → sembunyikan dialog, tampilkan badge hijau

**Endpoint:**
```
POST /api/rentals/{id}/idle/continue   ← user pilih lanjut
POST /api/rentals/{id}/finish          ← user pilih selesai
```

**Tambahkan ke `api_client.dart`:**
```dart
Future<void> continueIdle(int rentalId) async { ... }
```

**Cara test:**
1. Jalankan backend scheduler: `php artisan schedule:work`
2. Mulai sewa → biarkan simulator tidak kirim GPS selama 5 menit
3. Pastikan dialog muncul di mobile_user

---

### 🟠 Anggota 4 — Ahmad Jul Hadi (2301010019)
**Phase 5 — Bike Simulator Enhancement (Simulator App)**

**Tugas:** Tingkatkan fitur `mobile_bike` dengan kontrol manual koordinat GPS dan simulasi pergerakan otomatis (mock route), agar bisa di-test tanpa GPS fisik.

**File yang dikerjakan:**
```
mobile_bike/lib/src/features/simulator/
    manual_gps_panel.dart    ← panel input koordinat manual [BUAT BARU]
    mock_route_service.dart  ← service simulasi rute [BUAT BARU]
    (update simulator_screen.dart — tambah tab/panel baru)
```

**Fitur yang harus dibuat:**

**A. Manual GPS Input:**
- Field input Latitude & Longitude
- Tombol **Kirim Koordinat Ini** (override GPS dengan koordinat manual)
- Berguna saat test di emulator tanpa GPS aktif

**B. Mock Route Simulator:**
- Tombol **Simulasi Rute** — gerakkan koordinat perlahan dari titik A ke B
- Gunakan list koordinat statis (misalnya rute di sekitar kampus)
- Interval gerak: 5 detik per titik (sesuai GPS update interval)
- Tampilkan indikator "Simulasi Rute: Titik 3/10"

**Contoh mock route:**
```dart
const List<LatLng> mockRoute = [
  LatLng(-6.2134, 106.8456),
  LatLng(-6.2140, 106.8462),
  LatLng(-6.2148, 106.8470),
  // dst...
];
```

**Cara test:**
1. Jalankan mobile_bike
2. Aktifkan "Simulasi Rute"
3. Cek di admin panel: posisi sepeda harus bergerak sesuai rute
4. Cek di mobile_user (Riki + Arya): peta harus update

---

### 🔴 Anggota 5 — Ahmad Zaki Aldrin (2301010023)
**Phase 6 — Admin Settings UI (Web Admin Panel)**

**Tugas:** Buat halaman settings di admin panel Laravel Blade agar superadmin bisa mengubah parameter billing, GPS rules, dan idle rules.

**File yang dikerjakan (di `backend/`):**
```
resources/views/admin/settings/
    index.blade.php    ← halaman utama settings [BUAT BARU]
resources/views/admin/
    (update navigasi di layout)
app/Http/Controllers/Admin/
    SettingController.php    ← controller [BUAT BARU]
routes/web.php               ← tambah route settings
```

**Tampilan yang harus dibuat (grouped settings):**

**Group 1: Distance Billing**
- Jarak per unit (meter) — input number
- Harga per unit (Rp) — input number
- Rounding mode (floor/ceil) — select

**Group 2: Idle Rules**
- Idle warning setelah (detik) — input number
- Interval billing idle (detik) — input number
- Biaya idle per interval (Rp) — input number

**Group 3: GPS Rules**
- Interval update GPS (detik) — input number
- Minimum movement threshold (meter) — input number
- Akurasi GPS maksimum (meter) — input number

**Controller logic:**
```php
// Baca dari tabel pricing_settings
// Update menggunakan PricingConfigService yang sudah ada
```

**Route:**
```php
Route::get('/admin/settings', [SettingController::class, 'index']);
Route::post('/admin/settings', [SettingController::class, 'update']);
```

**Cara test:**
1. Login sebagai superadmin → buka `/admin/settings`
2. Ubah nilai → simpan
3. Cek tabel `pricing_settings` di database

---

### 🟣 Anggota 6 — Endah Komariah Lestari (2301010022)
**Phase 7 — Rental History & Detail (User App)**

**Tugas:** Buat halaman histori sewa di mobile_user yang menampilkan daftar rental yang sudah selesai beserta detail biaya.

**File yang dikerjakan:**
```
mobile_user/lib/src/features/history/
    history_screen.dart    ← daftar histori [BUAT BARU]
    rental_detail_screen.dart   ← detail satu rental [BUAT BARU]
mobile_user/lib/src/models/
    rental_history.dart    ← model histori [BUAT BARU]
```

**Tampilan History Screen:**
- List kartu rental (tanggal, bike code, total biaya, durasi)
- Status badge (completed / cancelled)
- Tap → buka detail

**Tampilan Rental Detail Screen:**
- Nama & kode sepeda
- Waktu mulai & selesai
- Durasi total
- Total jarak (km)
- Biaya jarak (Rp)
- Biaya idle (Rp)
- **Total Biaya (Rp)** — highlighted

**Endpoint:**
```
GET /api/rentals/history
Response: { data: [ { id, status, started_at, ended_at, total_distance_meters,
                      distance_cost, idle_cost, total_cost, bike: {...} } ] }
```

**Tambahkan ke `api_client.dart`:**
```dart
Future<List<Map<String, dynamic>>> rentalHistory() async { ... }
```

**Navigasi:** Tambahkan tab/tombol "Histori" di `home_screen.dart`

**Cara test:**
1. Selesaikan beberapa rental
2. Buka menu Histori → pastikan muncul
3. Tap salah satu → cek detail biaya sesuai

---

### 🩷 Anggota 7 — Anggilhami Dwi Kihantari (2301010054)
**Phase 7 — UI Polish & Splash Screen (User App)**

**Tugas:** Perbaiki tampilan keseluruhan mobile_user agar lebih premium: tambah splash screen, perbaiki home screen (daftar sepeda), dan tambah loading state yang proper di semua layar.

**File yang dikerjakan:**
```
mobile_user/lib/src/features/
    splash/splash_screen.dart        ← splash screen [BUAT BARU]
    home/home_screen.dart            ← redesign daftar sepeda
mobile_user/lib/src/app.dart         ← tambah splash ke routing
```

**A. Splash Screen:**
- Background gelap (`#0F172A`)
- Logo sepeda animasi (fade in)
- Nama app "Smart Bike Rental"
- Cek session → redirect ke login atau home
- Durasi: 2 detik

**B. Home Screen (Daftar Sepeda) — Redesign:**
- Kartu sepeda lebih informatif:
  - Badge status: 🟢 Tersedia / 🔴 Disewa / 🟡 Offline
  - Kode & nama sepeda
  - Indikator baterai
  - Tombol **Sewa Sekarang** (disable jika tidak available)
- Pull-to-refresh
- Empty state jika tidak ada sepeda

**C. Loading & Error States (semua screen):**
- Shimmer loading saat fetch data
- Error state dengan tombol retry
- SnackBar untuk feedback aksi (sukses/gagal)

**D. Update `pubspec.yaml` jika perlu:**
```yaml
# Opsional untuk shimmer effect
shimmer: ^3.0.0
```

**Cara test:**
1. Buka app → cek splash muncul dengan animasi
2. Cek home screen — semua sepeda tampil rapi dengan badge status
3. Matikan internet → cek error state muncul
4. Pull-to-refresh → data terupdate

---

## 📌 Cara Setup untuk Semua Anggota

### 1. Clone repo
```bash
git clone https://github.com/msaririzki/smart-bike.git
cd smart-bike-rental
```

### 2. Setup backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

### 3. Flutter (mobile_user atau mobile_bike)
```bash
cd mobile_user   # atau mobile_bike
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### 4. Akun demo
| Role | Email | Password |
|---|---|---|
| User | `user@smartbike.test` | `password` |
| Admin | `admin@smartbike.test` | `password` |
| Superadmin | `superadmin@smartbike.test` | `password` |
| Device | `device@smartbike.test` | `password` |

---

## 🌿 Alur Git untuk Tim

```bash
# Setiap anggota buat branch sendiri
git checkout -b feature/nama-fitur

# Kerjakan tugas...

# Commit dan push
git add .
git commit -m "feat: deskripsi fitur yang dikerjakan"
git push origin feature/nama-fitur

# Minta Project Lead (msaririzki) untuk merge ke main
```

**Nama branch yang disarankan:**
| Anggota | Branch |
|---|---|
| Riki | `feature/active-rental-screen` |
| Arya | `feature/live-map` |
| Adi | `feature/idle-warning-ui` |
| Jul Hadi | `feature/simulator-enhancement` |
| Zaki | `feature/admin-settings` |
| Endah | `feature/rental-history` |
| Anggil | `feature/ui-polish` |

---

## 🔗 Koordinasi Antar Anggota

> **Riki** mengerjakan `active_rental_screen.dart` terlebih dahulu karena **Adi** dan **Arya** akan mengintegrasikan kode mereka ke file yang sama.

| Urutan Prioritas | Alasan |
|---|---|
| 1. Riki (aktif rental screen) | Base screen untuk Adi & Arya |
| 2. Arya (map) + Adi (idle UI) | Integrasi ke screen Riki |
| 3. Jul Hadi (simulator) | Independen |
| 4. Zaki (admin settings) | Independen |
| 5. Endah (histori) | Independen |
| 6. Anggil (UI polish) | Setelah semua selesai |
