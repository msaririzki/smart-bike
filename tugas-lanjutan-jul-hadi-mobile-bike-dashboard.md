# Tugas Lanjutan Jul Hadi - Mobile Bike Dashboard

Tanggal: 12 Mei 2026  
Anggota: Ahmad Jul Hadi  
Area: `mobile_bike`  
Status: setelah update besar dashboard sepeda

---

## Fokus Utama

Jul Hadi perlu memastikan `mobile_bike` benar-benar siap menjadi dashboard perangkat sepeda.

Prinsip yang harus dijaga:

```text
GPS sepeda berasal dari mobile_bike
mobile_bike kirim ke backend
backend mengolah lokasi, jarak, biaya, dan status rental
mobile_user hanya menampilkan hasil dari backend
```

Manual GPS dan Mock Route hanya untuk demo/debug. Jalur utama tetap Real GPS dari HP/device.

---

## Yang Sudah Masuk

Fitur baru yang sudah tersedia:

- Dashboard Sepeda.
- Tombol utama `Mulai Kirim GPS Real`.
- Speedometer real-time.
- Mini route map lokal.
- Ringkasan rental aktif:
  - penyewa
  - status rental
  - durasi
  - total jarak
  - biaya jarak
  - biaya idle
  - total biaya
- Panel biaya satu baris:
  - Jarak
  - Idle
  - Total
- Panel device:
  - baterai
  - jaringan
  - titik terkirim
  - terakhir kirim
  - mode lokasi
  - status device
- Panel kontrol debug yang selalu terlihat.
- Endpoint backend:

```text
GET /api/device/active-rental-summary
```

- GPS memakai akurasi tinggi:

```text
LocationAccuracy.bestForNavigation
```

- Filter titik GPS buruk agar jalur tidak terlihat loncat-loncat.

---

## Tugas Prioritas Tinggi

### 1. Test Real GPS di HP Fisik

Tujuan:

memastikan dashboard mengambil koordinat dari GPS HP/device, bukan input manual.

Langkah:

1. Pull `main` terbaru.
2. Jalankan backend:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

3. Jalankan `mobile_bike` ke HP Android:

```bash
cd mobile_bike
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

4. Login sebagai akun device.
5. Pastikan akun device sudah di-assign ke sepeda.
6. Tekan `Mulai Kirim GPS Real`.
7. Berikan permission lokasi.
8. Bawa HP berjalan 20-50 meter.

Kriteria selesai:

- Mode lokasi menampilkan `Real GPS`.
- Speed berubah saat HP bergerak.
- Latitude/longitude berubah.
- Titik terkirim bertambah.
- Mini route map membentuk jalur.
- Server message tidak error.

---

### 2. Test Dashboard Dengan Rental Aktif

Tujuan:

memastikan dashboard menampilkan ringkasan rental dari backend.

Langkah:

1. Login `mobile_user` sebagai user.
2. User mulai rental sepeda yang sama dengan device.
3. Buka `mobile_bike`.
4. Tunggu polling ringkasan rental.
5. Tekan `Mulai Kirim GPS Real`.
6. Bawa HP berjalan.

Kriteria selesai:

- Dashboard menampilkan `Ringkasan Rental Aktif`.
- Nama penyewa tampil.
- Status rental tampil.
- Durasi berjalan.
- Total jarak bertambah jika pergerakan valid.
- Biaya jarak bertambah sesuai backend.
- Total biaya sesuai dengan `mobile_user` dan admin.

---

### 3. Test Mini Route Map

Tujuan:

memastikan jalur lokal di dashboard enak dilihat dan tidak loncat-loncat.

Yang harus dicek:

- titik awal muncul
- titik terbaru muncul
- garis jalur muncul setelah beberapa titik
- jumlah titik bertambah
- jalur tidak bergerak liar saat HP diam
- titik dengan GPS buruk tidak merusak jalur

Kriteria selesai:

- Jalur terlihat stabil saat berjalan.
- Jalur tidak berpindah jauh tiba-tiba tanpa alasan.
- Jika berada di dalam gedung dan akurasi buruk, dashboard memberi indikasi GPS kurang akurat.

Catatan:

Jika GPS tetap loncat, catat kondisi testing:

- indoor/outdoor
- jenis HP
- akurasi GPS yang tampil
- jaringan yang dipakai
- apakah battery saver aktif

---

### 4. Cocokkan Mobile Bike, Mobile User, dan Admin

Tujuan:

memastikan semua sisi membaca data yang konsisten.

Bandingkan:

- `mobile_bike` dashboard
- `mobile_user` Active Rental
- admin monitoring
- admin detail rental

Data yang harus cocok:

- kode sepeda
- status rental
- posisi terakhir
- total jarak
- biaya jarak
- biaya idle
- total biaya
- last update

Kriteria selesai:

- `mobile_user` map mengikuti data dari `mobile_bike`.
- admin dashboard map menampilkan sepeda.
- admin monitoring menampilkan heartbeat dan lokasi terbaru.
- detail rental admin menampilkan rute.

---

## Tugas Prioritas Sedang

### 5. Test Permission dan GPS Service

Skenario:

- permission lokasi diberikan
- permission lokasi ditolak
- GPS HP dimatikan
- battery saver aktif
- test indoor
- test outdoor

Kriteria selesai:

- App tidak crash.
- Jika permission ditolak, pesan jelas.
- Jika GPS buruk, kualitas GPS tampil.
- Real GPS tetap menjadi tombol utama.

---

### 6. Test Manual GPS dan Mock Route Sebagai Debug

Tujuan:

memastikan panel debug masih berguna tanpa membingungkan jalur utama.

Yang dites:

- kirim koordinat manual
- pilih preset lokasi
- jalankan mock route
- ubah interval 3/5/10 detik
- ubah mode berulang/berhenti/reset

Kriteria selesai:

- Manual GPS bisa mengirim titik.
- Mock route bisa membuat mini route map bergerak.
- Mode lokasi berubah jelas menjadi `Manual GPS` atau `Mock Route`.
- Tester tidak mengira manual/mock adalah GPS real.

---

### 7. Validasi UI di HP Kecil

Area yang harus dicek:

- speedometer
- mini route map
- ringkasan rental aktif
- panel biaya satu baris
- panel device
- tombol utama
- panel kontrol debug

Kriteria selesai:

- Tidak ada overflow.
- Panel biaya satu baris tetap terbaca.
- Tombol utama mudah ditekan.
- Mini route map tidak terlalu kecil.
- Panel debug tidak tersembunyi.

---

## Bukti yang Harus Dilaporkan

Jul Hadi perlu mengirim:

- screenshot dashboard sebelum mulai GPS
- screenshot saat `Real GPS` aktif
- screenshot speed berubah
- screenshot mini route map sudah membentuk jalur
- screenshot ringkasan rental aktif
- screenshot biaya jarak/idle/total
- screenshot Active Rental di `mobile_user`
- screenshot admin monitoring/detail rental jika sempat
- video pendek saat HP dibawa berjalan

Format catatan testing:

```text
Device:
Lokasi test:
Indoor/outdoor:
Jarak test:
Mode lokasi:
Akurasi GPS rata-rata:
Jumlah titik terkirim:
Apakah mini route stabil:
Apakah mobile_user mengikuti lokasi:
Catatan kendala:
```

---

## Perintah Verifikasi

Backend:

```bash
cd backend
php artisan test
php artisan route:list --path=api/device
```

Mobile bike:

```bash
cd mobile_bike
flutter analyze
flutter test
```

Testing HP:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

---

## Catatan Penting

Jika ingin hasil GPS lebih akurat:

- test di outdoor
- pastikan location service aktif
- matikan battery saver
- beri permission lokasi penuh
- tunggu beberapa detik sampai GPS stabil
- jangan hanya test di dalam ruangan

Aplikasi sudah meminta akurasi tinggi, tetapi hasil akhir tetap dipengaruhi kualitas GPS HP dan lingkungan testing.
