# Tugas Lanjutan Riki - Active Rental Screen

Tanggal: 11 Mei 2026  
Anggota: I Made Riki Widiastana Sanjaya  
Branch sebelumnya: `feature/active-rental-screen`  
Status: update terbaru sudah masuk ke `main`

---

## Kondisi Saat Ini

Update terakhir Riki sudah digabung ke `main`.

Yang sudah tersedia:

- `ActiveRentalScreen` lebih stabil.
- UI detail active rental sudah dipisah ke:
  - `mobile_user/lib/src/features/rental/active_rental_detail.dart`
- Model `Rental` sudah mendukung:
  - `latestLocationPoint`
  - fallback latitude/longitude
  - last GPS update time
  - network type
  - GPS accuracy
- Active Rental sudah menampilkan:
  - status rental
  - bike code dan bike name
  - live map
  - lokasi latitude/longitude
  - last update
  - network type
  - GPS accuracy
  - total distance
  - speed
  - duration
  - distance cost
  - idle cost
  - total cost
- Dialog idle warning tidak muncul berulang untuk rental yang sama.
- Tombol finish rental sudah diberi guard agar tidak double-submit.
- Root project punya script:
  - `npm run dev`
  - menjalankan backend, `mobile_user`, dan `mobile_bike` web secara bersamaan.

---

## Tugas Lanjutan Prioritas Tinggi

### 1. Test Active Rental End-to-End

Tujuan:

memastikan screen rental aktif benar-benar berjalan dari awal sampai akhir.

Langkah:

1. Pull `main` terbaru.
2. Jalankan backend.
3. Jalankan `mobile_user`.
4. Jalankan `mobile_bike`.
5. Login user.
6. Login device.
7. User mulai rental.
8. Device kirim lokasi dari simulator.
9. Buka Active Rental.
10. Pastikan data berubah saat simulator mengirim lokasi.
11. Selesaikan rental.
12. Pastikan user kembali ke Home.

Kriteria selesai:

- Active Rental terbuka setelah start rental.
- Map tampil jika koordinat tersedia.
- Jika koordinat belum tersedia, empty state koordinat muncul.
- Last update tampil.
- Network type tampil.
- GPS accuracy tampil jika tersedia.
- Distance, speed, dan cost berubah sesuai data backend.
- Finish rental berhasil dan tidak bisa ditekan berkali-kali.

---

### 2. Test Active Rental Dengan Mock Route Jul Hadi

Tujuan:

memastikan integrasi Active Rental dengan `mobile_bike` enhancement berjalan.

Langkah:

1. User mulai rental.
2. Jul Hadi aktifkan `Mock Route Simulation` di `mobile_bike`.
3. Riki cek Active Rental di `mobile_user`.

Kriteria selesai:

- Marker sepeda bergerak di map.
- Polyline route bertambah.
- Total distance bertambah.
- Speed berubah.
- Last update berubah setiap titik dikirim.
- Network type tetap terbaca.

Catatan:

Jika marker tidak bergerak, cek:

- apakah device sudah di-assign ke sepeda yang sama
- apakah user menyewa sepeda yang sama
- apakah backend menerima location update
- apakah endpoint `GET /rentals/active` mengirim `latest_location_point`

---

### 3. Test Idle Warning Dengan Adi

Tujuan:

memastikan active rental tidak bentrok dengan dialog idle warning.

Langkah:

1. Buat rental aktif.
2. Buat backend mengubah status menjadi `idle_warning`.
3. Buka Active Rental.
4. Tunggu polling 5 detik.

Kriteria selesai:

- Dialog idle warning muncul.
- Dialog hanya muncul sekali untuk rental yang sama.
- Tombol `Lanjutkan Sewa` berhasil mengubah status ke `idle_billing`.
- Tombol `Selesaikan Sewa` berhasil menyelesaikan rental.
- Jika status kembali `active`, dialog tertutup.

---

### 4. Test History Dengan Endah Setelah Finish Rental

Tujuan:

memastikan hasil Active Rental masuk ke Rental History.

Langkah:

1. Jalankan rental sampai ada distance/cost.
2. Selesaikan rental dari Active Rental.
3. Buka menu `Riwayat`.
4. Tap rental terbaru.

Kriteria selesai:

- Rental terbaru muncul di history.
- Bike code sama.
- Total distance sama atau sesuai pembulatan backend.
- Distance cost sama.
- Idle cost sama.
- Total cost sama.
- Started at dan ended at masuk akal.

---

## Tugas Lanjutan Prioritas Sedang

### 5. Rapikan State Refresh

Saat ini Active Rental melakukan:

- polling otomatis tiap 5 detik
- manual refresh dari AppBar
- pull-to-refresh

Tugas:

- Pastikan ketiganya tidak saling tabrakan.
- Pastikan `_isRefreshing` tidak membuat refresh manual terasa macet.
- Pastikan error dari polling silent tidak mengganggu user secara berlebihan.

Kriteria selesai:

- Manual refresh tetap bisa dipakai.
- Pull-to-refresh tetap bisa dipakai.
- Polling tetap jalan.
- Tidak ada loading spinner yang stuck.

---

### 6. Tambahkan Tampilan Status Data GPS

Tugas:

Tambahkan indikator sederhana untuk kualitas GPS.

Contoh:

- `GPS Akurat` jika accuracy <= 25 m
- `GPS Kurang Akurat` jika accuracy > 25 m
- `GPS Belum Tersedia` jika accuracy null

Letakkan di `active_rental_detail.dart`, dekat panel koneksi.

Kriteria selesai:

- User bisa tahu apakah posisi sepeda cukup akurat.
- Tidak membuat UI terlalu ramai.

---

### 7. Tambahkan Last Update Relative Time

Saat ini last update tampil sebagai jam/tanggal.

Tugas:

Tambahkan format relatif, contoh:

- `Baru saja`
- `15 detik lalu`
- `2 menit lalu`

Kriteria selesai:

- User lebih mudah memahami apakah data GPS masih fresh.
- Tetap tampil aman jika `recorded_at` null.

---

### 8. Validasi Active Rental di Layar Kecil

Tugas:

Test di ukuran layar kecil atau emulator kecil.

Cek area:

- status header
- map
- connection panel
- metric grid
- tombol finish rental

Kriteria selesai:

- Tidak ada overflow.
- Text tidak bertabrakan.
- Metric card masih terbaca.
- Tombol finish tetap mudah ditekan.

---

## Tugas Opsional

### 9. Tambahkan Tombol Recenter Map

Jika map digeser user, tombol ini mengembalikan map ke posisi sepeda terbaru.

Catatan:

Ini bisa dikerjakan bersama Arya karena berkaitan dengan `MapWidget`.

---

### 10. Route History Dari Backend

Saat ini route points di Active Rental dikumpulkan selama screen terbuka.

Masalah:

Jika screen ditutup lalu dibuka lagi, route sebelumnya bisa hilang.

Tugas lanjutan:

- Buat backend mengirim list location points rental aktif.
- Parse di Flutter menjadi `List<LatLng>`.
- Tampilkan route history dari backend.

Catatan:

Ini butuh koordinasi dengan backend dan Arya.

---

## Checklist yang Harus Dilaporkan Riki

Riki perlu melaporkan hasil berikut:

- [ ] Active Rental bisa dibuka setelah start rental.
- [ ] Active Rental aman saat koordinat belum tersedia.
- [ ] Map muncul saat koordinat tersedia.
- [ ] Marker bergerak saat simulator mengirim titik baru.
- [ ] Last update, network type, dan GPS accuracy tampil.
- [ ] Finish rental berhasil.
- [ ] Idle warning tidak muncul berulang.
- [ ] Rental selesai muncul di history.
- [ ] Tidak ada overflow di layar kecil.

---

## Catatan Teknis

Branch Riki sudah pernah conflict dengan Home karena fitur History juga mengubah bottom navigation.

Ke depannya, kalau mengedit `home_screen.dart`, pastikan:

- tombol `Riwayat` tetap ada
- `HistoryScreen(api: api)` tetap bisa dibuka
- active rental card tetap bisa membuka Active Rental
- bottom navigation tidak kembali ke versi lama

