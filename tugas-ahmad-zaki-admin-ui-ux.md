# Tugas Ahmad Zaki Aldrin - UI/UX Web Admin

Tanggal: 12 Mei 2026  
Nama: Ahmad Zaki Aldrin  
NIM: 2301010023  
Area: Web Admin Smart Bike Rental  
Target branch kerja: `feature/admin-ui-ux-polish`

---

## Tujuan Utama

Rapikan tampilan Web Admin agar terasa modern, nyaman di mata, mudah dipahami, dan konsisten memakai Bahasa Indonesia.

Fokus utama bukan menambah logic backend besar, tetapi memperbaiki pengalaman admin saat melihat:

- dashboard
- monitoring sepeda
- detail sepeda
- rental
- detail rental
- pengguna
- laporan
- peringatan
- pengaturan

Jangan menghapus fitur admin yang sudah ada. UI boleh dipoles, tetapi data, route, filter, peta, dan tabel harus tetap berfungsi.

---

## Kondisi Saat Ini

Fitur admin sudah ada, tetapi UI masih sederhana.

File penting:

- `backend/resources/views/layouts/admin.blade.php`
- `backend/resources/views/admin/dashboard.blade.php`
- `backend/resources/views/admin/monitoring/index.blade.php`
- `backend/resources/views/admin/monitoring/show.blade.php`
- `backend/resources/views/admin/bikes/index.blade.php`
- `backend/resources/views/admin/bikes/form.blade.php`
- `backend/resources/views/admin/rentals/index.blade.php`
- `backend/resources/views/admin/rentals/show.blade.php`
- `backend/resources/views/admin/users/index.blade.php`
- `backend/resources/views/admin/users/show.blade.php`
- `backend/resources/views/admin/reports/index.blade.php`
- `backend/resources/views/admin/alerts/index.blade.php`
- `backend/resources/views/admin/settings.blade.php`

Route utama:

- `/admin`
- `/admin/monitoring-bikes`
- `/admin/bikes`
- `/admin/rentals`
- `/admin/users`
- `/admin/reports`
- `/admin/alerts`
- `/admin/settings`

---

## Arahan Nuansa Tampilan

Gunakan nuansa:

- modern
- bersih
- ringan
- nyaman di mata
- mudah dipindai
- profesional untuk dashboard operasional
- tidak terlalu ramai
- tidak seperti landing page

Rekomendasi gaya:

- background abu-abu sangat muda
- kartu putih atau near-white
- warna utama hijau teal
- aksen biru untuk informasi
- merah hanya untuk bahaya/error/offline
- kuning/oranye untuk warning
- border halus
- radius card sekitar 8px
- shadow sangat tipis, jangan berlebihan
- spacing konsisten
- tabel mudah dibaca

Hindari:

- warna terlalu gelap di semua halaman
- gradasi berlebihan
- card terlalu banyak bersarang
- animasi yang tidak perlu
- teks bahasa Inggris campur-campur
- tampilan terlalu dekoratif sampai fungsi utama sulit dibaca

---

## Tugas Prioritas Tinggi

### 1. Rapikan Layout Admin Utama

File:

```text
backend/resources/views/layouts/admin.blade.php
```

Tugas:

- Ubah header dan navigasi agar lebih modern.
- Buat navigasi lebih mudah dibaca.
- Beri active state untuk menu yang sedang dibuka.
- Pastikan menu tidak berantakan di layar kecil.
- Rapikan style global:
  - body
  - header
  - nav
  - main
  - card
  - grid
  - table
  - button
  - badge
  - form input
  - alert/status message

Menu yang harus tetap ada:

- Dasbor
- Monitoring Sepeda
- Sepeda
- Rental
- Rental Aktif
- Pengguna
- Laporan
- Peringatan
- Pengaturan khusus superadmin
- Keluar

Kriteria selesai:

- Header terlihat rapi.
- Navigasi mudah dipakai.
- Layout tidak pecah di mobile/tablet.
- Semua link admin tetap berfungsi.

---

### 2. Konsistensi Bahasa Indonesia

Tugas:

Cek seluruh view admin dan ubah label yang masih terasa campur Bahasa Inggris.

Contoh yang harus diseragamkan:

- `Dashboard` menjadi `Dasbor`
- `Users` menjadi `Pengguna`
- `Reports` menjadi `Laporan`
- `Alerts` menjadi `Peringatan`
- `Settings` menjadi `Pengaturan`
- `Status Online` tetap boleh dipakai
- `Battery` menjadi `Baterai`
- `Network Type` menjadi `Jenis Jaringan`
- `Last Seen` menjadi `Terakhir Aktif`
- `Route Map` menjadi `Peta Rute`
- `Refresh` menjadi `Muat Ulang`
- `Search` menjadi `Cari`

Kriteria selesai:

- Semua halaman admin memakai Bahasa Indonesia yang konsisten.
- Istilah teknis tetap boleh dipertahankan jika umum, misalnya GPS, API, role.
- Tidak ada label penting yang masih campur tidak jelas.

---

### 3. Polish Dashboard Admin

File:

```text
backend/resources/views/admin/dashboard.blade.php
```

Tugas:

- Rapikan kartu statistik.
- Tambahkan icon sederhana untuk tiap metrik jika memungkinkan.
- Buat angka utama lebih jelas.
- Buat label lebih ringkas.
- Rapikan peta lokasi sepeda.
- Buat area peta terasa seperti panel monitoring, bukan sekadar kotak biasa.
- Pastikan tombol `Pusatkan Peta` jelas.
- Pastikan empty state peta mudah dipahami.

Kartu statistik yang harus tetap ada:

- Total Sepeda
- Sepeda Tersedia
- Sepeda Dipakai
- Sepeda Offline
- Rental Aktif
- Rental Selesai Hari Ini
- Estimasi Pendapatan
- Total Jarak Tempuh
- Pengguna

Kriteria selesai:

- Admin bisa langsung melihat kondisi operasional.
- Statistik mudah dipindai dalam 5 detik.
- Peta tetap muncul dan auto-refresh tetap jalan.
- Tidak ada teks yang bertabrakan.

---

### 4. Polish Monitoring Sepeda

File:

```text
backend/resources/views/admin/monitoring/index.blade.php
backend/resources/views/admin/monitoring/show.blade.php
```

Tugas halaman list:

- Rapikan filter status dan pencarian.
- Buat tombol `Filter`, `Muat Ulang`, dan `Hapus Filter` lebih jelas.
- Rapikan tabel agar tidak terasa terlalu padat.
- Beri warna badge yang konsisten untuk status sepeda.
- Buat status online/offline mudah terlihat.
- Baterai rendah harus mudah dikenali.
- Jika tidak ada data, empty state harus jelas.

Tugas halaman detail:

- Buat ringkasan sepeda di bagian atas.
- Kelompokkan informasi menjadi beberapa area:
  - status sepeda
  - lokasi terakhir
  - sinyal perangkat terakhir
  - rental aktif
  - heartbeat terakhir
  - lokasi rental terakhir
- Buat tabel heartbeat dan lokasi lebih rapi.
- Pastikan informasi penting tidak tenggelam.

Kriteria selesai:

- Admin cepat tahu sepeda online/offline.
- Admin cepat tahu baterai dan lokasi terakhir.
- Admin bisa memahami device yang terhubung.
- Detail sepeda mudah dibaca.

---

### 5. Polish Rental dan Detail Rental

File:

```text
backend/resources/views/admin/rentals/index.blade.php
backend/resources/views/admin/rentals/show.blade.php
```

Tugas list rental:

- Rapikan filter status rental.
- Buat status rental lebih mudah dibedakan.
- Tampilkan rental aktif dengan visual yang jelas.
- Tabel harus tetap mudah dibaca walau datanya banyak.

Tugas detail rental:

- Rapikan bagian data pengguna, data sepeda, dan ringkasan rental.
- Buat biaya lebih mudah dibaca:
  - Biaya Jarak
  - Biaya Sepeda Diam
  - Total Biaya
  - Total Jarak
- Peta rute harus tetap terlihat jelas.
- Riwayat tagihan, catatan idle, dan riwayat lokasi harus tetap mudah discan.

Kriteria selesai:

- Admin bisa memahami satu rental tanpa membaca tabel panjang dulu.
- Peta rute tidak pecah.
- Data biaya terlihat jelas.
- Status rental tidak membingungkan.

---

### 6. Polish Peringatan

File:

```text
backend/resources/views/admin/alerts/index.blade.php
backend/resources/views/admin/alerts/partials/bike-table.blade.php
```

Tugas:

- Buat halaman peringatan terlihat seperti pusat masalah operasional.
- Kelompokkan peringatan:
  - Sepeda Offline
  - Baterai Rendah
  - Rental Idle
  - GPS Tidak Update
  - Heartbeat Tidak Update
- Gunakan warna warning/error secara tepat.
- Tambahkan empty state jika tidak ada masalah.

Kriteria selesai:

- Admin bisa langsung tahu masalah paling penting.
- Peringatan tidak terlihat seperti tabel biasa saja.
- Jika semua aman, halaman tetap terlihat rapi.

---

## Tugas Prioritas Sedang

### 7. Polish Manajemen Pengguna

File:

```text
backend/resources/views/admin/users/index.blade.php
backend/resources/views/admin/users/show.blade.php
```

Tugas:

- Rapikan filter role dan pencarian user.
- Buat badge role lebih jelas:
  - pengguna
  - admin
  - superadmin
  - perangkat sepeda
- Detail user harus mudah membaca:
  - data user
  - jumlah rental
  - histori rental
  - sepeda yang di-assign jika role device
- Form update role untuk superadmin harus jelas dan tidak membingungkan.

Kriteria selesai:

- Admin mudah mencari user.
- Admin mudah membedakan user biasa dan device.
- Superadmin mudah mengganti role dengan aman.

---

### 8. Polish Laporan

File:

```text
backend/resources/views/admin/reports/index.blade.php
```

Tugas:

- Buat laporan terlihat seperti ringkasan bisnis/operasional.
- Rapikan tabel rental harian.
- Rapikan tabel sepeda paling sering dipakai.
- Rapikan bagian idle event.
- Angka rupiah dan jarak harus mudah dibaca.

Kriteria selesai:

- Laporan mudah dipakai untuk presentasi.
- Angka penting terlihat jelas.
- Tabel tidak terasa terlalu mentah.

---

### 9. Polish Pengaturan

File:

```text
backend/resources/views/admin/settings.blade.php
```

Tugas:

- Kelompok pengaturan harus terlihat jelas.
- Deskripsi setting harus mudah dibaca.
- Input tidak terlalu padat.
- Tombol simpan harus jelas.
- Beri visual pembeda untuk pengaturan penting:
  - biaya
  - idle
  - GPS
  - offline timeout

Kriteria selesai:

- Superadmin mudah memahami pengaturan.
- Tidak terasa seperti form panjang yang membingungkan.

---

## Komponen UI yang Sebaiknya Dibuat Konsisten

Jika memungkinkan, rapikan CSS global di:

```text
backend/resources/views/layouts/admin.blade.php
```

Komponen yang perlu konsisten:

- `.card`
- `.grid`
- `.toolbar`
- `.button`
- `.button.secondary`
- `.badge`
- `.muted`
- `.error`
- `.success`
- tabel
- input
- select
- empty state
- map panel

Jika class baru diperlukan, boleh tambahkan:

- `.page-header`
- `.page-title`
- `.page-subtitle`
- `.stat-card`
- `.stat-value`
- `.stat-label`
- `.status-dot`
- `.table-wrap`
- `.empty-state`
- `.danger-card`
- `.warning-card`
- `.info-card`

Catatan:

Jangan membuat terlalu banyak class yang hanya dipakai satu kali jika tidak perlu.

---

## Responsive dan Accessibility

Wajib dicek:

- Desktop normal.
- Tablet atau layar sedang.
- Mobile width.

Hal yang harus aman:

- Navigasi tidak pecah.
- Tabel bisa discroll horizontal jika kolom banyak.
- Peta tetap punya tinggi yang jelas.
- Tombol mudah ditekan.
- Form tidak keluar layar.
- Kontras teks cukup jelas.
- Badge status tetap terbaca.

Kriteria selesai:

- Tidak ada layout yang saling tumpang tindih.
- Tidak ada teks yang terpotong aneh.
- Tidak ada tabel yang merusak halaman.

---

## Larangan Penting

Jangan lakukan ini:

- Jangan menghapus route admin.
- Jangan menghapus peta Leaflet.
- Jangan menghapus endpoint JSON peta.
- Jangan menghapus filter status.
- Jangan mengubah logic billing.
- Jangan mengubah logic GPS.
- Jangan mengubah middleware auth/role.
- Jangan mengganti semua struktur backend tanpa alasan.
- Jangan membuat UI admin seperti landing page.
- Jangan menambah dependency frontend besar tanpa diskusi.

---

## Verifikasi Wajib

Jalankan dari folder `backend`:

```bash
php artisan route:list
php artisan test --filter=AdminMonitoringTest
php artisan test --filter=AdminPagesTest
```

Jika ada perubahan file PHP, cek syntax:

```bash
php -l app/Http/Controllers/Admin/DashboardController.php
php -l app/Http/Controllers/Admin/MonitoringController.php
php -l app/Http/Controllers/Admin/RentalController.php
```

Jika hanya mengubah Blade/CSS, minimal pastikan halaman ini bisa dibuka:

```text
/admin
/admin/monitoring-bikes
/admin/bikes
/admin/rentals
/admin/users
/admin/reports
/admin/alerts
/admin/settings
```

---

## Output yang Harus Dilaporkan Ahmad Zaki

Ahmad Zaki perlu melaporkan:

- Screenshot dashboard sebelum dan sesudah.
- Screenshot monitoring sepeda.
- Screenshot detail monitoring sepeda.
- Screenshot rental detail dengan peta rute.
- Screenshot halaman peringatan.
- Screenshot tampilan mobile atau layar kecil.
- Catatan halaman mana saja yang sudah dipoles.
- Catatan jika ada halaman yang belum sempat dipoles.
- Hasil test:

```text
php artisan test --filter=AdminMonitoringTest
php artisan test --filter=AdminPagesTest
```

---

## Prompt untuk AI Ahmad Zaki

Gunakan prompt ini jika Ahmad Zaki ingin meminta bantuan AI:

```text
Saya mengerjakan Web Admin Smart Bike Rental di backend Laravel.

Tugas saya adalah memperbaiki UI/UX admin agar modern, nyaman di mata, mudah dipahami, dan konsisten memakai Bahasa Indonesia.

Fitur admin yang sudah ada tidak boleh dihapus:
- Dashboard di /admin
- Peta lokasi sepeda dengan Leaflet
- Endpoint JSON /admin/dashboard/map-data
- Monitoring sepeda di /admin/monitoring-bikes
- Detail monitoring sepeda di /admin/monitoring-bikes/{bike}
- Manajemen sepeda di /admin/bikes
- Rental list di /admin/rentals
- Detail rental di /admin/rentals/{rental}
- Peta rute rental di detail rental
- Endpoint JSON /admin/rentals/{rental}/route-map-data
- Manajemen pengguna di /admin/users
- Detail user di /admin/users/{user}
- Laporan di /admin/reports
- Peringatan di /admin/alerts
- Pengaturan superadmin di /admin/settings

File yang perlu dipoles:
- backend/resources/views/layouts/admin.blade.php
- backend/resources/views/admin/dashboard.blade.php
- backend/resources/views/admin/monitoring/index.blade.php
- backend/resources/views/admin/monitoring/show.blade.php
- backend/resources/views/admin/bikes/index.blade.php
- backend/resources/views/admin/bikes/form.blade.php
- backend/resources/views/admin/rentals/index.blade.php
- backend/resources/views/admin/rentals/show.blade.php
- backend/resources/views/admin/users/index.blade.php
- backend/resources/views/admin/users/show.blade.php
- backend/resources/views/admin/reports/index.blade.php
- backend/resources/views/admin/alerts/index.blade.php
- backend/resources/views/admin/settings.blade.php

Arahan desain:
- Bahasa Indonesia konsisten
- Dashboard operasional, bukan landing page
- Modern, bersih, nyaman dilihat
- Background abu-abu muda
- Kartu putih/near-white
- Warna utama teal
- Biru untuk informasi
- Merah untuk bahaya/offline/error
- Kuning/oranye untuk warning
- Tabel rapi dan mudah dibaca
- Badge status jelas
- Responsive di mobile/tablet

Jangan ubah logic billing, GPS, middleware auth/role, route admin, atau endpoint JSON peta.

Setelah perubahan, jalankan:
php artisan route:list
php artisan test --filter=AdminMonitoringTest
php artisan test --filter=AdminPagesTest

Tolong bantu saya memoles tampilan admin secara bertahap, mengikuti struktur Blade dan CSS yang sudah ada.
```
