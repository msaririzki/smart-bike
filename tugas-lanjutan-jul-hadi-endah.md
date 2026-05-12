# Tugas Lanjutan Setelah Merge

Tanggal: 11 Mei 2026
Target branch utama: `main`
Anggota terkait:

- Ahmad Jul Hadi - `feature/simulator-enhancement`
- Endah Komariah Lestari - `feature/rental-history`

Status saat ini:

- `feature/simulator-enhancement` sudah masuk ke `main`.
- `feature/rental-history` sudah masuk ke `main`.
- `main` sudah dipush ke GitHub.

---

## 1. Ahmad Jul Hadi - Bike Simulator Enhancement

### Area Tanggung Jawab

App: `mobile_bike`
Fokus: simulator perangkat sepeda yang mengirim lokasi GPS ke backend.

File utama:

- `mobile_bike/lib/src/features/simulator/simulator_screen.dart`
- `mobile_bike/lib/src/features/simulator/manual_gps_panel.dart`
- `mobile_bike/lib/src/features/simulator/mock_route_service.dart`

### Yang Sudah Masuk ke Main

Fitur yang sudah tersedia:

- Panel input latitude dan longitude manual.
- Tombol untuk mengirim koordinat manual ke server.
- Mock route simulation.
- Simulator otomatis mengirim titik rute palsu setiap 5 detik.
- Status progress simulasi, contoh: `Simulasi Rute: Titik 3/10`.
- Tombol `Stop Stream` sudah menghentikan mock route timer juga.

Fungsi fitur:

- Manual GPS input dipakai untuk mengetes titik tertentu tanpa GPS fisik.
- Mock route simulation dipakai untuk demo pergerakan sepeda tanpa harus membawa sepeda berjalan.
- Real GPS stream tetap dipakai untuk testing paling realistis dengan HP yang ditempel di sepeda.

### Tugas Lanjutan Prioritas Tinggi

1. Test real GPS di HP Android.

   Tujuan:
   memastikan `mobile_bike` benar-benar bisa membaca lokasi HP dan mengirimnya ke backend.

   Langkah:

   - Jalankan backend di laptop:
     ```bash
     php artisan serve --host=0.0.0.0 --port=8000
     ```
   - Jalankan `mobile_bike` di HP Android dengan IP laptop:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
     ```
   - Login sebagai akun device.
   - Pastikan device sudah di-assign ke sepeda.
   - Tekan `Mulai Stream GPS`.
   - Bawa HP berjalan beberapa meter.
   - Pastikan backend menerima lokasi.
   - Pastikan `mobile_user` menampilkan posisi sepeda yang berubah.

   Kriteria selesai:

   - Latitude dan longitude berubah di simulator.
   - `pointsSent` bertambah.
   - Server response berhasil.
   - Posisi sepeda di user app ikut berubah.

2. Test mock route end-to-end.

   Tujuan:
   memastikan demo tetap bisa dilakukan tanpa keluar ruangan.

   Langkah:

   - Login `mobile_bike` sebagai device.
   - Login `mobile_user` sebagai user.
   - User mulai rental untuk sepeda yang sama.
   - Di `mobile_bike`, aktifkan `Simulasi Rute Otomatis`.
   - Buka Active Rental di `mobile_user`.

   Kriteria selesai:

   - Titik rute mock terkirim setiap 5 detik.
   - Marker sepeda di map user berpindah.
   - Polyline route muncul.
   - Total distance bertambah.
   - Distance cost ikut berubah sesuai backend.

3. Test manual GPS input.

   Tujuan:
   memastikan input koordinat manual bisa dipakai untuk debug cepat.

   Langkah:

   - Masukkan latitude dan longitude valid.
   - Tekan `Kirim Koordinat Ini`.
   - Cek server response.
   - Cek posisi di `mobile_user`.

   Kriteria selesai:

   - Input valid berhasil dikirim.
   - Input tidak valid menampilkan pesan error.
   - Koordinat terbaru tampil di Active Rental map.

### Tugas Lanjutan Prioritas Sedang

1. Tambahkan preset lokasi.

   Contoh preset:

   - Kampus
   - Parkiran
   - Gerbang
   - Titik demo 1
   - Titik demo 2

   Tujuan:
   agar tester tidak perlu mengetik latitude/longitude manual setiap kali demo.

2. Tambahkan pilihan interval simulasi.

   Opsi:

   - 3 detik
   - 5 detik
   - 10 detik

   Tujuan:
   agar demo bisa dipercepat atau diperlambat.

3. Tambahkan pilihan mode mock route.

   Opsi:

   - loop terus
   - berhenti di titik terakhir
   - reset ke titik awal

   Saat ini mock route cenderung reset setelah titik terakhir.

4. Tambahkan indikator mode lokasi aktif.

   Contoh status:

   - `Mode: Real GPS`
   - `Mode: Manual GPS`
   - `Mode: Mock Route`

   Tujuan:
   agar saat presentasi jelas data lokasi berasal dari mana.

### Risiko yang Harus Dicek

- Jika backend masih memakai `127.0.0.1`, HP tidak bisa mengakses backend laptop.
- Jika permission lokasi belum diberikan, real GPS tidak jalan.
- Jika device belum di-assign ke bike, simulator tidak bisa mengirim data untuk sepeda yang benar.
- Jika user menyewa sepeda berbeda dari device assignment, map user tidak akan mengikuti simulator.

### Output yang Harus Dilaporkan Jul Hadi

Jul Hadi perlu melaporkan:

- Apakah real GPS berhasil di HP.
- Apakah mock route berhasil menggerakkan map di `mobile_user`.
- Apakah manual GPS input berhasil.
- Screenshot/video pendek:
  - simulator mengirim titik
  - user app menampilkan marker bergerak
- Kendala device/backend jika ada.

---

## 2. Endah Komariah Lestari - Rental History

### Area Tanggung Jawab

App: `mobile_user`
Fokus: riwayat rental user dan detail biaya perjalanan.

File utama:

- `mobile_user/lib/src/features/history/history_screen.dart`
- `mobile_user/lib/src/features/history/rental_detail_screen.dart`
- `mobile_user/lib/src/models/rental_history.dart`
- `mobile_user/lib/src/services/api_client.dart`
- `mobile_user/lib/src/features/home/home_screen.dart`

### Yang Sudah Masuk ke Main

Fitur yang sudah tersedia:

- Screen daftar riwayat sewa.
- Screen detail satu riwayat sewa.
- Model `RentalHistory`.
- API client method `rentalHistory()`.
- Tombol `Riwayat` di bottom navigation Home.
- Format tanggal Indonesia via `initializeDateFormatting('id_ID')`.
- Summary:
  - total jarak
  - total sewa
  - estimasi CO2 saved
  - aktivitas 7 hari
  - badge pencapaian
- Detail perjalanan:
  - bike code
  - status
  - tanggal
  - durasi
  - jarak
  - average speed
  - estimasi kalori
  - biaya jarak
  - biaya idle
  - total biaya
  - highlight perjalanan

### Tugas Lanjutan Prioritas Tinggi

1. Test API history dengan backend real.

   Endpoint:

   ```text
   GET /api/rentals/history
   ```

   Langkah:

   - Login sebagai user.
   - Selesaikan minimal 2 rental.
   - Buka menu `Riwayat`.
   - Pastikan data rental completed muncul.
   - Tap salah satu item.
   - Pastikan detail sesuai dengan data backend.

   Kriteria selesai:

   - History list tidak kosong setelah rental selesai.
   - Bike code tampil benar.
   - Total cost sesuai backend.
   - Distance cost dan idle cost sesuai backend.
   - Started at dan ended at tampil benar.

2. Test empty state.

   Tujuan:
   memastikan user baru yang belum pernah rental tidak melihat error.

   Langkah:

   - Login dengan user baru.
   - Buka `Riwayat`.

   Kriteria selesai:

   - Muncul pesan `Belum ada riwayat sewa`.
   - Tidak crash.
   - Tidak loading terus-menerus.

3. Test error state.

   Tujuan:
   memastikan error API ditangani dengan baik.

   Langkah:

   - Matikan backend.
   - Buka `Riwayat`.

   Kriteria selesai:

   - Error message muncul.
   - Tombol `Coba Lagi` tersedia.
   - App tidak crash.

### Tugas Lanjutan Prioritas Sedang

1. Tambahkan filter status.

   Opsi:

   - Semua
   - Completed
   - Cancelled

   Tujuan:
   memudahkan user melihat riwayat tertentu.

2. Tambahkan filter periode.

   Opsi:

   - 7 hari terakhir
   - bulan ini
   - semua

   Tujuan:
   summary 7 hari dan total history bisa lebih mudah dipahami.

3. Tambahkan pull-to-refresh pada empty/error state.

   Saat ini refresh sudah ada di list. Pastikan state kosong dan error juga nyaman untuk retry.

4. Rapikan highlight perjalanan.

   Saat ini highlight masih berupa modal visual. Berikutnya bisa ditingkatkan menjadi:

   - tombol share
   - export gambar
   - copy ringkasan perjalanan

5. Validasi teks estimasi.

   Beberapa nilai seperti CO2 dan kalori masih estimasi. Tambahkan label yang jelas agar tidak dianggap data resmi.

   Contoh:

   - `Estimasi CO2`
   - `Estimasi Kalori`

### Risiko yang Harus Dicek

- Endpoint backend mengembalikan data dalam bentuk pagination.
- `rentalHistory()` sudah menangani `data.data`, tapi tetap perlu dites dengan response real.
- Jika `started_at` null, model sekarang fallback ke `DateTime.now()`. Ini aman dari crash, tapi bisa membuat tanggal tampak salah. Lebih baik backend selalu mengirim `started_at`.
- Jika `ended_at` null, durasi tampil `0` atau `-`. Untuk history completed, backend seharusnya mengirim `ended_at`.
- History screen memakai banyak komponen visual; perlu dicek di layar kecil agar tidak overflow.

### Output yang Harus Dilaporkan Endah

Endah perlu melaporkan:

- Screenshot daftar history yang berisi data real.
- Screenshot detail salah satu rental.
- Bukti total biaya di detail sama dengan backend.
- Bukti empty state aman.
- Bukti error state aman.
- Catatan jika ada overflow di layar kecil.

---

## Testing Gabungan Jul Hadi dan Endah

Tujuan:

memastikan simulator bisa membuat data rental nyata, lalu data itu muncul di history setelah rental selesai.

Langkah:

1. Jalankan backend.
2. Jalankan `mobile_bike`.
3. Jalankan `mobile_user`.
4. Login `mobile_bike` sebagai device.
5. Login `mobile_user` sebagai user.
6. User mulai rental.
7. Jul Hadi aktifkan mock route di `mobile_bike`.
8. Pastikan marker di Active Rental bergerak.
9. Selesaikan rental dari `mobile_user`.
10. Endah buka menu `Riwayat`.
11. Pastikan rental yang baru selesai muncul.
12. Buka detail rental.
13. Cocokkan:
    - bike code
    - durasi
    - total distance
    - distance cost
    - idle cost
    - total cost

Kriteria sukses:

- Simulator menghasilkan data lokasi.
- Backend menghitung rental.
- User app menampilkan active rental.
- Setelah selesai, rental muncul di history.
- Detail history sesuai dengan rental yang baru dilakukan.

---

## Pembagian Kerja Praktis

### Jul Hadi

Fokus minggu ini:

- Real GPS test.
- Mock route end-to-end test.
- Manual GPS validation.
- Tambahkan preset lokasi jika waktu cukup.

### Endah

Fokus minggu ini:

- History API test.
- Empty state dan error state test.
- Validasi detail biaya.
- Cek tampilan di layar kecil.

### Koordinasi

Jul Hadi dan Endah perlu melakukan satu test bersama:

- Jul Hadi membuat data rental dari simulator.
- Endah memastikan rental tersebut muncul di history setelah selesai.
