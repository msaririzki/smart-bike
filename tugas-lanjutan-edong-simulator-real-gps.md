# Tugas Lanjutan Edong / Jul Hadi - Simulator Real GPS

Tanggal: 11 Mei 2026  
Anggota: Edong / Ahmad Jul Hadi  
Branch sebelumnya: `feature/simulator-enhancement`  
Status: update terbaru sudah masuk ke `main`

---

## Kondisi Saat Ini

Update terbaru dari `feature/simulator-enhancement` sudah digabung ke `main` dan dipush ke GitHub.

Yang sudah tersedia di `mobile_bike`:

- Manual GPS input.
- Preset lokasi manual.
- Mock route simulation.
- Pilihan interval simulasi:
  - 3 detik
  - 5 detik
  - 10 detik
- Pilihan mode simulasi:
  - berulang
  - berhenti di titik terakhir
  - reset
- Indikator mode lokasi:
  - `Real GPS`
  - `Manual GPS`
  - `Mock Route`
- Label UI simulator sudah lebih banyak memakai Bahasa Indonesia.

Catatan penting:

Manual GPS dan Mock Route hanya untuk debug, demo, dan testing cepat. Untuk penggunaan nyata, lokasi sepeda harus berasal dari GPS HP/device yang ditempel di sepeda.

---

## Prioritas Utama

### 1. Pastikan Real GPS Menjadi Jalur Utama

Tujuan:

memastikan simulator benar-benar mengambil latitude dan longitude dari GPS HP, bukan hanya dari input manual.

Yang harus dicek:

- Tombol `Mulai Kirim Lokasi` harus menjalankan Real GPS stream.
- App meminta permission lokasi.
- Setelah permission diberikan, latitude dan longitude berubah mengikuti posisi HP.
- Indikator mode menampilkan:

```text
Mode: Real GPS
```

- Data yang dikirim ke backend memakai koordinat dari `Geolocator`, bukan koordinat yang diketik manual.

Kriteria selesai:

- HP berpindah posisi, latitude/longitude ikut berubah.
- `Titik Terkirim` bertambah otomatis.
- `Terakhir Kirim` berubah secara berkala.
- Backend menerima data lokasi terbaru.
- `mobile_user` menampilkan posisi sepeda yang ikut berubah di Active Rental.

---

### 2. Test di HP Android Fisik

Tujuan:

menguji kondisi paling dekat dengan skenario nyata, yaitu HP/device ditempel di sepeda.

Langkah:

1. Pull `main` terbaru.
2. Jalankan backend di laptop:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

3. Pastikan HP dan laptop berada di jaringan WiFi yang sama.
4. Jalankan `mobile_bike` ke HP Android:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

5. Login sebagai akun device.
6. Pastikan device sudah di-assign ke sepeda yang benar.
7. Tekan `Mulai Kirim Lokasi`.
8. Izinkan permission lokasi.
9. Bawa HP berjalan minimal 20-50 meter.
10. Cek apakah koordinat di simulator berubah.
11. Cek apakah Active Rental di `mobile_user` ikut bergerak.

Kriteria selesai:

- Real GPS berhasil jalan di HP fisik.
- Tidak perlu mengetik latitude/longitude manual.
- Koordinat berubah sesuai perpindahan HP.
- Map user mengikuti lokasi sepeda.
- Tidak ada error permission.

---

### 3. Validasi Permission Lokasi

Tujuan:

memastikan app aman saat permission lokasi belum diberikan atau ditolak.

Skenario yang harus dites:

- Permission lokasi diberikan.
- Permission lokasi ditolak.
- Permission lokasi dimatikan dari Settings HP.
- GPS/location service HP dimatikan.

Kriteria selesai:

- Jika permission diberikan, Real GPS berjalan.
- Jika permission ditolak, app menampilkan pesan yang jelas.
- Jika GPS HP mati, app tidak crash.
- User tahu harus mengaktifkan lokasi agar streaming berjalan.

---

### 4. Bedakan Jelas Real GPS, Manual GPS, dan Mock Route

Tujuan:

mencegah tester mengira data manual/mock adalah data GPS asli.

Tugas:

- Pastikan indikator mode selalu benar.
- Jika `Mulai Kirim Lokasi` ditekan, mode harus menjadi `Real GPS`.
- Jika koordinat manual dikirim, mode harus menjadi `Manual GPS`.
- Jika simulasi rute dinyalakan, mode harus menjadi `Mock Route`.
- Saat stop stream, mode kembali kosong atau `None`.

Kriteria selesai:

- Saat presentasi, sumber koordinat terlihat jelas.
- Tidak ada kondisi mode salah tampil.
- Manual dan mock tidak dianggap sebagai data real.

---

## Tugas Lanjutan Prioritas Tinggi

### 5. Kirim Akurasi GPS ke Backend

Tujuan:

agar backend dan user app bisa tahu kualitas lokasi.

Yang dicek:

- Nilai `accuracyMeters` dikirim saat Real GPS.
- Nilai akurasi tampil di simulator.
- Nilai akurasi tampil di Active Rental user app jika backend mengembalikan data tersebut.

Kriteria selesai:

- Akurasi GPS muncul dalam meter.
- Jika akurasi buruk, tester bisa mengetahuinya.
- Data manual boleh memakai akurasi `0`, tapi Real GPS harus memakai nilai asli dari device.

---

### 6. Test Real GPS Bersama Active Rental

Tujuan:

memastikan data GPS dari `mobile_bike` benar-benar dipakai oleh user yang sedang menyewa sepeda.

Langkah:

1. Login `mobile_bike` sebagai device.
2. Login `mobile_user` sebagai user.
3. Pastikan device di-assign ke sepeda yang sama dengan sepeda yang disewa user.
4. User mulai rental.
5. Di `mobile_bike`, tekan `Mulai Kirim Lokasi`.
6. Bawa HP/device berpindah.
7. Buka Active Rental di `mobile_user`.

Kriteria selesai:

- Marker sepeda di map user berpindah.
- Last update berubah.
- Network type tampil.
- GPS accuracy tampil.
- Total distance bertambah jika perpindahan valid.
- Total cost ikut berubah sesuai perhitungan backend.

---

### 7. Dokumentasikan Bukti Testing

Edong / Jul Hadi perlu melaporkan bukti berikut:

- Screenshot mode `Real GPS`.
- Screenshot koordinat berubah di simulator.
- Screenshot `Titik Terkirim` bertambah.
- Screenshot Active Rental user yang marker-nya bergerak.
- Catatan jarak testing, contoh:

```text
HP dibawa berjalan sekitar 30 meter di area kampus.
Koordinat berubah dari ... ke ...
Active Rental berhasil update dalam ... detik.
```

- Catatan kendala jika ada:
  - permission
  - API base URL
  - device assignment
  - GPS tidak akurat
  - backend tidak menerima data

---

## Tugas Prioritas Sedang

### 8. Tambahkan Status GPS Service

Tugas:

tampilkan status apakah location service HP aktif atau tidak.

Contoh tampilan:

```text
GPS Service: Aktif
GPS Service: Tidak Aktif
```

Kriteria selesai:

- User tahu apakah GPS HP sedang aktif.
- Jika GPS mati, beri pesan yang jelas.

---

### 9. Tambahkan Indikator Kualitas GPS

Tugas:

tampilkan kualitas GPS berdasarkan akurasi.

Contoh:

- `GPS Akurat` jika akurasi <= 25 meter
- `GPS Sedang` jika akurasi 26-50 meter
- `GPS Buruk` jika akurasi > 50 meter

Kriteria selesai:

- Tester bisa tahu apakah data GPS layak dipakai.
- Indikator tidak mengganggu UI utama.

---

### 10. Pastikan Timer Real GPS dan Mock Route Tidak Bertabrakan

Tujuan:

mencegah Real GPS dan Mock Route mengirim data bersamaan.

Kriteria selesai:

- Saat Mock Route dinyalakan, Real GPS stream berhenti.
- Saat Real GPS dinyalakan, Mock Route berhenti.
- Tombol stop menghentikan timer yang sedang aktif.
- Tidak ada pengiriman lokasi diam-diam setelah stop.

---

## Checklist Laporan Edong / Jul Hadi

- [ ] Pull `main` terbaru.
- [ ] `flutter analyze` di `mobile_bike` bersih.
- [ ] Real GPS berhasil jalan di HP fisik.
- [ ] Permission lokasi sudah dites.
- [ ] Koordinat berubah tanpa input manual.
- [ ] Data lokasi terkirim otomatis ke backend.
- [ ] Active Rental di `mobile_user` mengikuti lokasi Real GPS.
- [ ] Manual GPS tetap bisa dipakai untuk debug.
- [ ] Mock Route tetap bisa dipakai untuk demo.
- [ ] Real GPS, Manual GPS, dan Mock Route tidak berjalan bersamaan.
- [ ] Bukti screenshot/video pendek sudah disiapkan.

---

## Catatan Teknis

Manual GPS dan Mock Route jangan dihapus, karena tetap berguna untuk debug dan demo. Namun untuk skenario nyata, jalur utama yang harus dibuktikan adalah:

```text
GPS HP/device -> mobile_bike -> backend -> mobile_user Active Rental
```

Jika testing memakai HP fisik, jangan memakai:

```text
http://127.0.0.1:8000/api
```

Gunakan IP laptop:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

Pastikan device user sudah di-assign ke sepeda yang sama dengan sepeda yang sedang dirental oleh user.
