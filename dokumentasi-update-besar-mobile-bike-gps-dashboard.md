# Dokumentasi Update Besar Mobile Bike GPS Dashboard

Dokumen ini menjelaskan perubahan besar pada aplikasi `mobile_bike` setelah update dashboard sepeda, GPS real, foreground tracking, dan persiapan testing langsung di HP.

## Ringkasan Perubahan

`mobile_bike` sekarang diarahkan menjadi dashboard perangkat sepeda, bukan sekadar simulator input koordinat. Aplikasi ini dipakai pada HP/perangkat yang ditempel di sepeda untuk membaca GPS asli, mengirim posisi ke server, dan menampilkan kondisi rental secara real-time.

Perubahan utama:

- GPS real aktif otomatis setelah device login dan sudah punya assignment sepeda.
- Aplikasi meminta akses lokasi saat dashboard dibuka.
- Tracking GPS berjalan dengan foreground notification Android.
- Layar HP tetap menyala selama dashboard `mobile_bike` terbuka.
- Kecepatan real-time dihitung dari GPS, dengan fallback dari jarak antar titik.
- Dashboard menampilkan checklist tes lapangan.
- Timestamp GPS dikirim ke server lewat `recorded_at`.
- Status pengiriman dipisah antara GPS terbaca dan server menerima.
- Manual GPS dan mock route tetap ada, tapi hanya untuk debug/demo.

## Alur Sistem Saat Ini

```text
Admin assign akun device ke sepeda
        |
mobile_bike login sebagai akun device
        |
mobile_bike mengambil assignment sepeda dari server
        |
mobile_bike meminta izin lokasi dan notifikasi
        |
GPS real aktif otomatis
        |
mobile_bike membaca koordinat, akurasi, dan kecepatan
        |
mobile_bike mengirim lokasi ke backend
        |
backend menyimpan lokasi, menghitung jarak, idle, dan biaya
        |
mobile_user dan admin menampilkan lokasi/jalur dari data mobile_bike
```

## Perubahan Detail di Mobile Bike

### 1. GPS Aktif Otomatis

Sebelumnya user perlu menekan tombol `Mulai Kirim GPS Real`. Sekarang, setelah login device berhasil dan akun device sudah terhubung ke sepeda, aplikasi akan otomatis menyalakan GPS real.

Kondisi auto-start:

- Akun sudah login sebagai device.
- Device sudah di-assign ke sepeda.
- Izin lokasi diberikan.
- GPS/lokasi HP aktif.
- App tidak sedang menjalankan mock route.

Tombol yang tersisa hanya untuk kontrol manual:

- `Hentikan Sementara`
- `Aktifkan GPS Sekarang`
- `Kirim Heartbeat Manual`

### 2. Permission Lokasi Saat Dashboard Dibuka

Saat user masuk ke dashboard, aplikasi langsung mengecek izin lokasi.

Jika izin belum diberikan, aplikasi menampilkan panel peringatan dengan tombol:

- `Minta Izin Lokasi`
- `Aktifkan GPS`
- `Buka Pengaturan Aplikasi`

Jika izin lokasi pernah ditolak permanen, tester harus membuka pengaturan aplikasi Android secara manual dan mengizinkan lokasi.

### 3. Foreground Tracking Android

Tracking GPS sekarang memakai foreground notification Android.

Notifikasi yang muncul:

```texta
Smart Bike sedang mengirim lokasi
GPS sepeda aktif agar admin dan penyewa bisa memantau lokasi.
```

Tujuannya:

- GPS tetap lebih stabil saat app diminimize.
- Android tahu aplikasi sedang melakukan tracking lokasi.
- Tester bisa melihat bahwa tracking sepeda sedang aktif.

Permission Android yang ditambahkan:

- `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`
- `WAKE_LOCK`

Catatan:

Foreground notification membantu tracking tetap jalan, tetapi jika user membunuh aplikasi dari recent apps atau battery saver terlalu agresif, Android tetap bisa menghentikan proses.

### 4. Layar Tetap Hidup Seperti Speedometer

Karena `mobile_bike` berfungsi seperti dashboard/speedometer sepeda, layar HP sekarang dibuat tetap menyala selama aplikasi terbuka.

Implementasi Android:

```text
FLAG_KEEP_SCREEN_ON
```

Efeknya:

- Saat dashboard `mobile_bike` tampil, layar tidak otomatis sleep.
- Cocok untuk testing langsung di HP.
- Jika layar dikunci manual, layar tetap mati seperti normal.

### 5. Kecepatan Real-Time Lebih Stabil

Sebelumnya kecepatan bisa tetap `0.0 km/h` karena beberapa HP Android tidak selalu mengisi nilai `pos.speed`.

Sekarang aplikasi memakai dua sumber:

- Kecepatan bawaan GPS Android jika tersedia.
- Fallback dari jarak antar titik GPS dibagi waktu.

Dengan begitu, saat sepeda/HP benar-benar bergerak, angka kecepatan lebih mungkin berubah.

### 6. Refresh GPS Berkala

Selain stream GPS berdasarkan pergerakan, aplikasi juga mengambil posisi berkala setiap interval.

Tujuannya:

- Server tetap menerima update walaupun sepeda diam.
- Status seperti `GPS 3 menit lalu` tidak terus muncul saat app sebenarnya masih aktif.
- Admin dan mobile user bisa tahu device masih hidup.

### 7. Timestamp GPS Dikirim ke Server

`mobile_bike` sekarang mengirim `recorded_at` dari timestamp GPS device.

Ini penting agar backend bisa menghitung:

- waktu pergerakan
- jarak
- kecepatan
- idle
- biaya

secara lebih akurat dibanding hanya memakai waktu request diterima server.

### 8. Status GPS dan Server Dipisah

Dashboard sekarang membedakan dua status:

- `GPS dibaca`: kapan sensor GPS terakhir berhasil dibaca dari HP.
- `Server menerima`: kapan backend terakhir berhasil menerima data.

Ini membantu debugging.

Contoh interpretasi:

- GPS baru, server lama: jaringan/API bermasalah.
- GPS lama, server lama: sensor GPS/permission/app bermasalah.
- GPS baru, server baru: tracking normal.

### 9. Checklist Tes Lapangan

Dashboard `mobile_bike` sekarang punya panel `Checklist Tes Lapangan`.

Item yang dicek:

- Izin lokasi
- GPS perangkat
- Tracking otomatis
- Jaringan
- GPS dibaca
- Server menerima
- Akurasi GPS
- Rental aktif

Jika belum ada rental aktif, aplikasi tetap bisa mengirim lokasi untuk monitoring admin. Namun jarak, biaya, dan idle belum dihitung sebagai rental.

### 10. Manual GPS dan Mock Route Tetap Ada

Panel debug masih tersedia:

- Manual GPS
- Mock route
- Interval simulasi
- Mode rute

Namun ini hanya untuk demo/testing. Untuk penggunaan nyata, gunakan GPS real otomatis.

## Perubahan yang Berhubungan dengan Mobile User

Karena GPS berasal dari `mobile_bike`, bukan dari `mobile_user`, tampilan peta di `mobile_user` diperjelas.

Label yang ditambahkan:

- `Lokasi sepeda terakhir`
- `Jalur dari perangkat sepeda`

Pesan detail juga menjelaskan bahwa koordinat dan jalur berasal dari data yang dikirim perangkat sepeda.

## Cara Testing di HP

### 1. Build APK Mobile Bike

```bash
cd mobile_bike
flutter build apk --release --dart-define=API_BASE_URL=https://bike.ikydev.site/api
```

### 2. Install APK ke HP yang Dipasang di Sepeda

Pastikan:

- GPS HP aktif.
- Internet aktif.
- Battery saver dimatikan untuk aplikasi.
- Izin lokasi diberikan.
- Izin notifikasi diberikan.

Untuk Android, disarankan:

```text
Pengaturan > Aplikasi > Bike Simulator > Baterai > Tidak dibatasi
```

### 3. Login sebagai Device

Login memakai akun device yang sudah di-assign ke sepeda oleh admin.

Jika belum ada assignment, dashboard akan menampilkan:

```text
Belum ada sepeda yang di-assign ke akun ini.
```

### 4. Cek Dashboard Mobile Bike

Pastikan checklist menunjukkan:

- Izin lokasi: hijau
- GPS perangkat: hijau
- Tracking otomatis: hijau
- Jaringan: bukan offline
- GPS dibaca: beberapa detik lalu
- Server menerima: beberapa detik lalu

### 5. Cek Foreground Notification

Saat GPS aktif, Android harus menampilkan notifikasi:

```text
Smart Bike sedang mengirim lokasi
```

Jika notifikasi tidak muncul, cek izin notifikasi aplikasi.

### 6. Cek Layar Tetap Hidup

Biarkan dashboard terbuka beberapa menit. Layar tidak boleh sleep otomatis.

### 7. Mulai Rental dari Mobile User

Dari `mobile_user`:

- Login sebagai user.
- Pilih sepeda.
- Mulai rental.
- Buka rental aktif.

Peta harus menampilkan:

- Lokasi sepeda terakhir.
- Jalur dari perangkat sepeda jika sudah ada beberapa titik GPS.

### 8. Tes Jalan

Bawa HP/perangkat `mobile_bike` bergerak.

Yang perlu dicek:

- Kecepatan berubah.
- Koordinat berubah.
- Jalur mulai terbentuk.
- `Server menerima` tetap baru.
- Total jarak bertambah.
- Biaya jarak bertambah sesuai konfigurasi.

## Masalah Umum dan Cara Membaca Gejalanya

### Permission lokasi tidak muncul

Kemungkinan:

- Izin sudah pernah ditolak permanen.
- Aplikasi perlu dibuka dari pengaturan Android.

Solusi:

```text
Pengaturan > Aplikasi > Bike Simulator > Izin > Lokasi > Izinkan
```

### GPS tetap lama

Jika `GPS dibaca` lama:

- GPS HP mati.
- Sinyal GPS buruk.
- App tidak punya izin lokasi.
- HP masuk mode hemat baterai.

### Server menerima lama

Jika `GPS dibaca` baru tetapi `Server menerima` lama:

- Internet bermasalah.
- Token login expired.
- API domain tidak bisa diakses.
- Backend sedang error.

### Kecepatan tetap 0

Kemungkinan:

- HP tidak benar-benar bergerak cukup jauh.
- GPS belum stabil.
- Lokasi hanya berubah sangat kecil.

Solusi:

- Tes di luar ruangan.
- Bergerak minimal beberapa meter.
- Tunggu akurasi GPS membaik.

### Tidak ada jarak dan biaya

Kemungkinan:

- Belum ada rental aktif.
- Sepeda hanya monitoring, belum disewa.
- GPS buruk sehingga titik diabaikan backend.

Pastikan `mobile_user` sudah memulai rental untuk sepeda yang sama.

## Catatan untuk Tim

Poin penting agar tidak salah konsep:

- GPS real selalu berasal dari `mobile_bike`.
- `mobile_user` hanya menampilkan lokasi dan jalur dari server.
- Admin memonitor data yang dikirim `mobile_bike`.
- Manual GPS dan mock route hanya alat debug, bukan alur penggunaan nyata.
- Untuk tes lapangan, gunakan HP fisik, bukan emulator.

## Commit Terkait

Perubahan besar ini berasal dari beberapa commit:

- `fd92516` - request permission GPS saat dashboard dibuka
- `a8f01dd` - auto start GPS tracking
- `68a8079` - dashboard checklist dan status GPS/server
- `aae0dbc` - foreground tracking dan label peta mobile user
- `dcfaa9c` - layar dashboard tetap hidup
