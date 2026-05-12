# Catatan Merge 3 Branch Fitur

Tanggal catatan: 7 Mei 2026  
Target branch: `main`  
Status: ketiga branch sudah digabung dan sudah dipush ke `origin/main`.

Branch yang sudah masuk:

- `feature/active-rental-screen`
- `feature/live-map`
- `feature/idle-warning-ui`

Commit terbaru di `main` setelah integrasi:

- `7735600` - Integrate idle warning into active rental
- `c24b005` - Merge branch `feature/idle-warning-ui`
- `90805db` - Merge branch `feature/live-map`
- `ec866ad` - Merge branch `feature/active-rental-screen`

Verifikasi terakhir:

- `flutter analyze` pada `mobile_user`: lolos, `No issues found`.
- `main` lokal sudah sinkron dengan `origin/main`.

---

## Ringkasan Kondisi Setelah Merge

Setelah tiga branch digabung, aplikasi user sekarang sudah punya alur rental aktif yang lebih lengkap:

1. User bisa mulai rental dari Home.
2. Setelah rental dimulai, app membuka `ActiveRentalScreen`.
3. Home menampilkan kartu rental aktif.
4. Active rental melakukan polling ke backend setiap 5 detik.
5. Durasi rental berjalan real-time tiap 1 detik.
6. Active rental menampilkan status, sepeda, biaya, jarak, speed, map, dan koordinat.
7. Map menampilkan posisi sepeda dan route points selama screen aktif.
8. User bisa menyelesaikan rental.
9. Saat backend mengirim status `idle_warning`, dialog idle warning muncul otomatis.
10. Dari dialog, user bisa memilih `Lanjutkan Sewa` atau `Selesaikan Sewa`.

---

## 1. Riki - `feature/active-rental-screen`

### Yang Sudah Dikerjakan

Riki mengerjakan fondasi utama active rental.

File utama:

- `mobile_user/lib/src/features/rental/active_rental_screen.dart`
- `mobile_user/lib/src/features/home/home_screen.dart`
- `mobile_user/lib/src/models/rental.dart`
- `mobile_user/lib/src/services/api_client.dart`
- `backend/app/Http/Controllers/Api/RentalController.php`
- `backend/app/Models/Rental.php`

Fitur yang sudah tersedia:

- Membuat `ActiveRentalScreen`.
- Menghubungkan Home ke Active Rental.
- Setelah start rental, user diarahkan ke detail rental aktif.
- Home menampilkan active rental card.
- Active rental polling ke `GET /rentals/active` tiap 5 detik.
- Timer durasi berjalan setiap detik.
- Menampilkan:
  - status rental
  - bike code
  - bike name
  - total distance
  - current speed
  - duration
  - distance cost
  - idle cost
  - total cost
- Menyediakan tombol `Selesaikan Sewa`.
- Menambah parsing field rental:
  - `startedAt`
  - `currentSpeedKmh`
  - `totalDistanceKilometers`
- Backend active rental sudah include:
  - relation `bike`
  - relation `latestLocationPoint`
  - attribute `current_speed_kmh`

### Yang Berubah Setelah Digabung Dengan Branch Lain

Setelah branch Arya dan Adi masuk, screen Riki sekarang juga:

- Menampilkan live map dari `MapWidget`.
- Menyimpan route points selama screen aktif.
- Menampilkan koordinat latitude/longitude.
- Menampilkan `StatusBadge`.
- Memunculkan dialog idle warning otomatis.
- Memanggil `continueIdle()` jika user memilih lanjut saat idle.

### Tugas Lanjutan Riki

Prioritas tinggi:

- Pastikan `ActiveRentalScreen` tetap stabil saat data backend belum lengkap, misalnya bike belum punya latitude/longitude.
- Tambahkan tampilan `last update time` dari data GPS terakhir.
- Tambahkan tampilan `network_type` atau status koneksi dari simulator bike jika endpoint sudah mengirim data tersebut.
- Pastikan tombol `Selesaikan Sewa` tidak bisa ditekan ganda saat request sedang berjalan.
- Uji flow lengkap:
  - start rental
  - masuk active rental
  - polling data berubah
  - finish rental
  - kembali ke Home

Prioritas sedang:

- Pisahkan widget besar di `active_rental_screen.dart` jika file mulai terlalu panjang.
- Tambahkan empty state khusus jika rental aktif ada, tetapi koordinat sepeda belum tersedia.
- Tambahkan manual refresh yang tidak bentrok dengan polling otomatis.
- Pastikan route points direset saat rental berbeda dibuka.

Koordinasi dengan Arya:

- Tentukan apakah route points cukup dari polling app atau perlu diambil dari backend.
- Jika backend menyediakan histori titik lokasi, Riki perlu menambahkan model/API parsing untuk route history.

Koordinasi dengan Adi:

- Pastikan status `idle_warning` dan `idle_billing` dari backend selalu konsisten.
- Pastikan dialog idle tidak muncul berulang-ulang saat polling masih menerima status yang sama.

---

## 2. Arya - `feature/live-map`

### Yang Sudah Dikerjakan

Arya mengerjakan komponen peta dan routing.

File utama:

- `mobile_user/lib/src/features/rental/map_widget.dart`
- `mobile_user/lib/src/features/rental/routing_service.dart`
- `mobile_user/pubspec.yaml`
- `mobile_user/android/app/src/main/AndroidManifest.xml`

Fitur yang sudah tersedia:

- Menambahkan dependency:
  - `flutter_map`
  - `latlong2`
- Membuat `MapWidget`.
- Menampilkan tile map OpenStreetMap.
- Menampilkan marker posisi sepeda.
- Menampilkan polyline route points.
- Mendukung beberapa mode peta di komponen:
  - standard
  - satellite
  - hybrid
- Menyediakan helper:
  - `calculateDistance`
  - `totalRouteDistance`
- Membuat `RoutingService` untuk:
  - route request ke OSRM
  - reverse geocode ke Nominatim
- Menambahkan permission internet/network untuk Android.

Catatan integrasi:

- `map_test_screen.dart` tidak dimasukkan ke `main` karena hanya layar testing sementara.
- `geolocator` tidak dimasukkan karena active rental saat ini memakai koordinat sepeda dari backend, bukan GPS user langsung.
- `MapWidget` sudah dipasang di `ActiveRentalScreen`.

### Yang Berubah Setelah Digabung Dengan Branch Lain

Map sekarang bukan lagi fitur testing terpisah. Map sudah menjadi bagian dari active rental:

- Posisi map diambil dari `rental.bike.latitude` dan `rental.bike.longitude`.
- Route points dikumpulkan saat polling active rental.
- Jika latitude/longitude null, map tidak ditampilkan agar app tidak crash.

### Tugas Lanjutan Arya

Prioritas tinggi:

- Uji map dengan data GPS real dari bike simulator.
- Pastikan marker sepeda berpindah saat backend menerima lokasi baru.
- Pastikan polyline route tampil saat sepeda bergerak.
- Pastikan map tetap aman saat internet lambat atau tile map gagal dimuat.
- Pastikan map tidak terlalu berat saat route points makin banyak.

Prioritas sedang:

- Tambahkan limit route points di sisi UI agar list tidak tumbuh tanpa batas.
- Tambahkan fallback tampilan jika map tile gagal dimuat.
- Tambahkan tombol center/focus ke posisi sepeda.
- Tambahkan label ringkas untuk lokasi terakhir.
- Evaluasi apakah mode satellite/hybrid benar-benar diperlukan untuk demo.

Prioritas lanjutan:

- Integrasikan `RoutingService` jika aplikasi perlu rute rekomendasi, bukan hanya jejak perjalanan.
- Ambil route history dari backend agar jalur tetap muncul walau screen ditutup lalu dibuka lagi.
- Tambahkan marker start dan marker posisi terakhir yang lebih jelas jika dibutuhkan untuk presentasi.

Koordinasi dengan Riki:

- Tentukan format data route history dari backend ke Flutter.
- Jika route history dibuat, Arya perlu bantu mapping `rental_location_points` ke `List<LatLng>`.

Koordinasi dengan backend/device:

- Pastikan field koordinat yang dikirim konsisten:
  - `current_latitude`
  - `current_longitude`
  - `speed_kmh`
  - `recorded_at`

---

## 3. Adi - `feature/idle-warning-ui`

### Yang Sudah Dikerjakan

Adi mengerjakan UI idle warning dan status badge.

File utama:

- `mobile_user/lib/src/features/rental/idle_warning_dialog.dart`
- `mobile_user/lib/src/features/rental/idle_badge_widget.dart`
- `mobile_user/lib/src/services/api_client.dart`

Fitur yang sudah tersedia:

- Membuat `IdleWarningDialog`.
- Dialog menampilkan informasi bahwa sepeda diam selama 5 menit.
- Dialog menyediakan tombol:
  - `Lanjutkan Sewa`
  - `Selesaikan Sewa`
- Dialog punya state loading saat request sedang diproses.
- Membuat `StatusBadge`.
- Status badge mendukung:
  - `active`
  - `idle_warning`
  - `idle_billing`
  - status lain
- Menambahkan API client method:
  - `continueIdle(int rentalId)`

Catatan integrasi:

- `idle_test_screen.dart` tidak dimasukkan ke `main` karena hanya layar testing sementara.
- Dialog idle sudah dipasang ke `ActiveRentalScreen`.
- Badge status sudah dipakai di header Active Rental.

### Yang Berubah Setelah Digabung Dengan Branch Lain

Idle warning sekarang sudah berjalan dalam flow rental aktif:

- Active rental polling status dari backend.
- Jika status menjadi `idle_warning`, dialog otomatis muncul.
- Jika user pilih `Lanjutkan Sewa`, app memanggil endpoint:
  - `POST /rentals/{id}/idle/continue`
- Jika user pilih `Selesaikan Sewa`, app memanggil endpoint:
  - `POST /rentals/{id}/finish`
- Jika status berubah dari `idle_warning` ke status lain, dialog ditutup.

### Tugas Lanjutan Adi

Prioritas tinggi:

- Uji dialog idle warning dengan backend sungguhan.
- Pastikan dialog hanya muncul sekali saat status tetap `idle_warning`.
- Pastikan tombol `Lanjutkan Sewa` mengubah status backend menjadi `idle_billing`.
- Pastikan tombol `Selesaikan Sewa` benar-benar menutup rental.
- Pastikan loading state tidak membuat tombol bisa ditekan berkali-kali.

Prioritas sedang:

- Sesuaikan teks idle warning dengan setting backend jika durasi idle tidak selalu 5 menit.
- Tampilkan informasi biaya idle per interval jika backend menyediakan datanya.
- Tambahkan handling jika `continueIdle()` gagal karena rental sudah selesai atau status sudah berubah.
- Rapikan tampilan badge agar konsisten dengan desain active rental.

Prioritas lanjutan:

- Tambahkan local notification atau in-app banner jika user sedang tidak membuka active rental screen.
- Tambahkan status explanation singkat untuk `idle_billing`, misalnya "Biaya idle sedang berjalan".
- Tambahkan test manual scenario:
  - active ke idle_warning
  - idle_warning ke idle_billing
  - idle_warning ke completed
  - idle_billing balik ke active saat sepeda bergerak

Koordinasi dengan Riki:

- Pastikan dialog idle tidak bentrok dengan navigation Home/Active Rental.
- Pastikan finish rental dari dialog dan finish rental dari tombol utama memakai flow yang sama.

Koordinasi dengan backend:

- Pastikan endpoint `continueIdle` sudah mengembalikan status yang benar.
- Pastikan backend punya rule jika user tidak menekan apa pun saat `idle_warning`.

---

## Checklist Testing Gabungan

Checklist ini sebaiknya dilakukan setelah semua orang pull `main` terbaru.

### Scenario 1 - Start Rental Normal

- [ ] Login sebagai user.
- [ ] Pilih sepeda available.
- [ ] Tekan `Sewa`.
- [ ] App membuka Active Rental.
- [ ] Data sepeda tampil.
- [ ] Durasi berjalan.
- [ ] Total biaya tampil.

### Scenario 2 - GPS Update dan Map

- [ ] Jalankan bike simulator.
- [ ] Kirim lokasi awal.
- [ ] Active Rental menampilkan map.
- [ ] Marker sepeda tampil di koordinat terbaru.
- [ ] Kirim lokasi kedua yang berbeda.
- [ ] Marker berpindah.
- [ ] Polyline route muncul.
- [ ] Speed terbaru tampil.

### Scenario 3 - Finish Rental

- [ ] Dari Active Rental, tekan `Selesaikan Sewa`.
- [ ] Backend mengubah rental ke `completed`.
- [ ] Bike kembali available.
- [ ] User kembali ke Home.
- [ ] Home tidak lagi menampilkan rental aktif.

### Scenario 4 - Idle Warning

- [ ] Buat backend mengubah rental ke `idle_warning`.
- [ ] Active Rental menerima status dari polling.
- [ ] Dialog idle warning muncul otomatis.
- [ ] Badge status menunjukkan `IDLE WARNING`.

### Scenario 5 - Continue Idle

- [ ] Pada dialog idle, tekan `Lanjutkan Sewa`.
- [ ] Request `continueIdle` berhasil.
- [ ] Dialog tertutup.
- [ ] Status berubah ke `idle_billing`.
- [ ] Badge status menunjukkan `IDLE BILLING`.
- [ ] Biaya idle bertambah sesuai rule backend.

### Scenario 6 - Finish Dari Dialog Idle

- [ ] Buat rental masuk `idle_warning`.
- [ ] Pada dialog idle, tekan `Selesaikan Sewa`.
- [ ] Rental selesai.
- [ ] Dialog tertutup.
- [ ] User kembali ke Home.

---

## Catatan Risiko

1. Live map masih polling, belum websocket.
2. Route points belum diambil dari histori backend, jadi route bisa hilang jika screen ditutup lalu dibuka ulang.
3. Idle warning bergantung penuh pada status dari backend.
4. Teks "5 menit" di dialog masih hardcoded.
5. Jika backend belum mengirim latitude/longitude bike, map tidak akan tampil.
6. Jika backend belum menjalankan idle detection scheduler/service, dialog idle tidak akan muncul.

---

## Rekomendasi Urutan Kerja Berikutnya

1. Semua anggota pull `main` terbaru.
2. Riki uji flow active rental dari start sampai finish.
3. Arya uji map dengan data GPS dari simulator.
4. Adi uji idle warning dengan status dari backend.
5. Setelah manual test sukses, tim lanjut ke fitur history rental dan route history.
6. Setelah itu baru polish UI dan persiapan demo.

