# Catatan Pengerjaan Berdasarkan Histori Main

Dokumen ini dibuat dari histori commit yang sudah masuk ke branch `main` sampai commit `3e156aa` pada 12 Mei 2026 pukul 11:15 WITA.

Sumber utama:
- `git log --first-parent main` untuk melihat urutan pekerjaan yang benar-benar masuk ke `main`.
- `git log main` untuk melihat commit asli dari branch fitur yang ikut masuk melalui merge.
- File tugas lokal hanya dipakai untuk melengkapi nama anggota jika histori Git memakai username.

Catatan penting:
- NIM hanya ditulis jika tersedia di dokumen lokal atau informasi tim yang sudah tercatat.
- Jika NIM tidak ditemukan di histori Git atau file tugas, statusnya ditulis `Belum tercatat`.
- Nama pekerjaan di bawah ini mengikuti isi commit, branch, dan konteks fitur yang sudah digabung ke `main`.

## Ringkasan Anggota

| Nama | Username Git / Email | NIM | Fokus Pengerjaan |
| --- | --- | --- | --- |
| msaririzki | `msaririzki` / `msaririzki12@gmail.com` | Belum tercatat | Inisialisasi project, backend API, mobile app awal, integrasi branch, admin monitoring, mobile_bike dashboard, Docker deploy, perbaikan GPS, dan konfigurasi server |
| I Made Riki Widiastana Sanjaya | `Riki Sanjaya` / `imaderikiwidiastanasanjaya@gmail.com` | Belum tercatat | Active rental screen, polling rental aktif, data lokasi terakhir, dan dukungan development script |
| Arya | `dekca445` / `suthawijaya445@gmail.com` | Belum tercatat | Live map, dynamic route, real-time GPS tracking, dan OSRM routing |
| Adi Saputra | `Adi Saputra` / `adisaputrait21@gmail.com` | Belum tercatat | Idle warning UI, status badge, dan API continue idle |
| Ahmad Jul Hadi | `Edong` / `julbedong@gmail.com` | Belum tercatat | Simulator mobile_bike, manual GPS, mock route, preset lokasi, interval, dan indikator mode |
| Endah Komariah Lestari | `endahh` / `endahkomarialestari@gmail.com` | Belum tercatat | Rental history, detail riwayat, filter, redesign UI history, dan journey highlight |
| Anggil | `anggil` / `anggilkelra@gmail.com` | Belum tercatat | UI polish awal, splash folder, dan sinkronisasi branch UI polish |
| Ahmad Zaki Aldrin | `zakialdrin` / `ahmdzaki249@gmail.com` | 2301010023 | Polish UI/UX web admin, bahasa Indonesia, dashboard interaktif, analytics, dan responsive navigation |

## Catatan Per Tanggal

## 5 Mei 2026

### msaririzki

Commit terkait:
- `36bd6a6` - `first commit`
- `f6d4c5a` - `feat: add mobile_user flutter app and backend API setup`
- `9f670c3` - `docs: update README with complete setup guide for team`
- `596ba60` - `feat: add mobile_bike flutter simulator app (Phase 3)`
- `75df7ee` - `fix: perbaiki nama universitas menjadi Universitas Bumigora`

Pekerjaan yang tercatat:
- Membuat fondasi awal repository Smart Bike Rental.
- Menambahkan aplikasi `mobile_user` berbasis Flutter.
- Menambahkan setup backend API awal.
- Menulis panduan setup project di README agar tim bisa menjalankan project.
- Menambahkan aplikasi `mobile_bike` sebagai simulator perangkat sepeda.
- Memperbaiki nama universitas menjadi Universitas Bumigora.

### I Made Riki Widiastana Sanjaya

Commit terkait:
- `b11070d` - `Add latest location point and speed to rentals`
- `f0160a3` - `Add Active Rental screen and API support`

Pekerjaan yang tercatat:
- Menambahkan dukungan data titik lokasi terakhir pada rental.
- Menambahkan data kecepatan pada rental.
- Membuat screen Active Rental di `mobile_user`.
- Menambahkan dukungan API untuk mengambil dan menampilkan rental aktif.

## 6 Mei 2026

### Adi Saputra

Commit terkait:
- `8edb241` - `feat: idle warning dialog, status badge, dan continueIdle API (Adi - Anggota 3)`

Pekerjaan yang tercatat:
- Membuat dialog peringatan saat rental masuk status idle warning.
- Membuat status badge untuk menampilkan status rental dengan lebih jelas.
- Menambahkan dukungan API `continueIdle` agar user bisa melanjutkan rental setelah peringatan idle.

## 7 Mei 2026

### I Made Riki Widiastana Sanjaya

Commit terkait:
- `a87cd41` - `tambah opsi web untuk app mobile_bike`
- `c52ff6c` - `feat(mobile-user): stabilize active rental live screen`

Pekerjaan yang tercatat:
- Menambahkan opsi web untuk menjalankan app `mobile_bike`.
- Menstabilkan tampilan live Active Rental di `mobile_user`.
- Memperbaiki alur tampilan rental aktif agar siap menerima integrasi live map dan idle warning.

### Arya

Commit terkait:
- `b1373a6` - `feat: complete Live Map implementation with dynamic routing and UI tweaks`
- `94b2e75` - `feat(live-map): implement real-time GPS tracking with OSRM routing`

Pekerjaan yang tercatat:
- Membuat implementasi Live Map.
- Menambahkan dynamic routing.
- Menambahkan tracking GPS real-time.
- Menggunakan OSRM routing untuk visualisasi jalur.
- Melakukan penyesuaian UI pada map agar lebih enak dilihat dan dipakai.

### msaririzki

Commit terkait:
- `ec866ad` - `Merge branch 'feature/active-rental-screen'`
- `90805db` - `Merge branch 'feature/live-map'`
- `c24b005` - `Merge branch 'feature/idle-warning-ui'`
- `7735600` - `Integrate idle warning into active rental`

Pekerjaan yang tercatat:
- Menggabungkan branch `feature/active-rental-screen` ke `main`.
- Menggabungkan branch `feature/live-map` ke `main`.
- Menggabungkan branch `feature/idle-warning-ui` ke `main`.
- Mengintegrasikan idle warning ke Active Rental agar dialog dan status idle bisa muncul di flow rental aktif.

## 8 Mei 2026

### I Made Riki Widiastana Sanjaya

Commit terkait:
- `6793ea3` - `tambah script jalankan ketiga app dalam development`

Pekerjaan yang tercatat:
- Menambahkan script untuk menjalankan tiga bagian project pada mode development.
- Membantu workflow developer agar backend, `mobile_user`, dan `mobile_bike` lebih mudah dijalankan saat testing.

## 10 Mei 2026

### Ahmad Jul Hadi

Commit terkait:
- `b007a4f` - `feat: implement manual GPS input and mock route simulation for bike simulator (Jul Hadi)`

Pekerjaan yang tercatat:
- Menambahkan input GPS manual pada `mobile_bike`.
- Menambahkan simulasi rute palsu atau mock route.
- Membuat `mobile_bike` bisa mengirim koordinat ke server tanpa harus membawa sepeda berjalan.
- Menyiapkan dasar testing lokasi sepeda sebelum real GPS disempurnakan.

### Endah Komariah Lestari

Commit terkait:
- `bb1ddc0` - `feat: implement rental history and detail (Endah)`
- `ea64d63` - `feat: complete redesign of rental history and detail with premium dashboard UI, health metrics, and journey highlight`

Pekerjaan yang tercatat:
- Membuat fitur Rental History.
- Membuat halaman detail riwayat rental.
- Mendesain ulang tampilan riwayat rental dengan gaya dashboard premium.
- Menambahkan health metrics.
- Menambahkan journey highlight untuk ringkasan perjalanan.

### Anggil

Commit terkait:
- `935b344` - `setup ui polish branch and splash folder`

Pekerjaan yang tercatat:
- Menyiapkan branch UI polish.
- Menambahkan folder splash sebagai dasar pengerjaan polish tampilan aplikasi.

## 11 Mei 2026

### msaririzki

Commit terkait:
- `6fa99db` - `Merge branch 'feature/simulator-enhancement'`
- `25dae4a` - `Clean simulator enhancement merge noise`
- `a8f878e` - `Fix simulator mock route stop control`
- `560051e` - `Merge branch 'feature/rental-history'`
- `5ceffa0` - `Clean rental history merge noise`
- `1734578` - `Merge branch 'feature/active-rental-screen'`
- `f4f0f17` - `Merge branch 'feature/rental-history'`
- `e56e177` - `Clean rental history final update`
- `f95196e` - `Fix rental history final update lint and config`
- `d34ad01` - `Add admin bike monitoring features`
- `7ace630` - `Merge remote-tracking branch 'origin/feature/ui-polish'`
- `7366fd4` - `Merge remote-tracking branch 'origin/feature/simulator-enhancement'`
- `26ae208` - `chore: clean simulator merge whitespace`

Pekerjaan yang tercatat:
- Menggabungkan branch simulator enhancement ke `main`.
- Membersihkan hasil merge simulator agar tidak menyisakan noise.
- Memperbaiki tombol Stop Stream agar mock route simulation ikut berhenti.
- Menggabungkan branch Rental History ke `main`.
- Membersihkan hasil merge Rental History.
- Menggabungkan update lanjutan Active Rental ke `main`.
- Memperbaiki lint dan konfigurasi setelah finalisasi Rental History.
- Menambahkan fitur awal web admin untuk monitoring sepeda.
- Menggabungkan branch UI polish.
- Menggabungkan update lanjutan simulator enhancement.

### Endah Komariah Lestari

Commit terkait:
- `85385c6` - `feat: finalisasi fitur riwayat rental, filter status/periode, desain wrapped premium, dan ux shortcut ke beranda`

Pekerjaan yang tercatat:
- Finalisasi fitur riwayat rental.
- Menambahkan filter berdasarkan status.
- Menambahkan filter berdasarkan periode.
- Menyempurnakan desain wrapped premium.
- Menambahkan shortcut UX ke beranda.

### Ahmad Jul Hadi

Commit terkait:
- `381ee3e` - `feat: enhance simulator with presets, interval control, and mode indicators`
- `40c54bc` - `docs: finalize Indonesian translations and fix minor syntax in simulator`

Pekerjaan yang tercatat:
- Menambahkan preset pada simulator.
- Menambahkan kontrol interval pengiriman lokasi.
- Menambahkan indikator mode agar jelas apakah simulator memakai manual GPS, mock route, atau mode lain.
- Merapikan terjemahan bahasa Indonesia.
- Memperbaiki syntax kecil pada simulator.

### Anggil

Commit terkait:
- `9b611d0` - `Merge branch 'main' of https://github.com/msaririzki/smart-bike into feature/ui-polish`
- `de432db` - `Merge branch 'main' of https://github.com/msaririzki/smart-bike into feature/ui-polish`

Pekerjaan yang tercatat:
- Melakukan sinkronisasi branch `feature/ui-polish` dengan update terbaru dari `main`.
- Menjaga branch UI polish tetap mengikuti perubahan utama project sebelum digabung.

### Ahmad Zaki Aldrin

Commit terkait:
- `3d5bdc6` - `feat: poles tampilan dashboard dan perbaikan bahasa indonesia`

Pekerjaan yang tercatat:
- Mulai memoles tampilan dashboard admin.
- Memperbaiki penggunaan bahasa Indonesia pada halaman admin.
- Menyiapkan arah UI/UX admin agar lebih modern dan mudah dipahami.

## 12 Mei 2026

### Ahmad Zaki Aldrin

Commit terkait:
- `d84ab88` - `chore: clean up local files and sync with main`
- `913cf16` - `work in progress: polesan tambahan untuk halaman admin`
- `d9e6fe6` - `feat: complete interactive dashboard with analytics, and responsive navigation`

Pekerjaan yang tercatat:
- Membersihkan file lokal dan menyamakan branch dengan `main`.
- Melanjutkan polesan tambahan halaman admin.
- Menyelesaikan dashboard admin yang lebih interaktif.
- Menambahkan analytics pada dashboard.
- Menambahkan responsive navigation agar admin nyaman dipakai pada ukuran layar berbeda.

### msaririzki

Commit terkait:
- `752c2b6` - `feat: add mobile bike dashboard summary`
- `317627f` - `chore: add docker deployment setup`
- `2895b21` - `chore: update ikydev deploy domain and ports`
- `0b9deda` - `fix: use php 8.4 for docker backend`
- `53b090f` - `fix: avoid blank app key env override in docker`
- `fbf555a` - `fix: regenerate invalid docker app key`
- `be8008f` - `fix: force https behind tunnel`
- `15be0eb` - `feat: polish admin ui ux`
- `fd92516` - `fix: request bike gps permission on dashboard`
- `a8f01dd` - `fix: auto start bike gps tracking`
- `68a8079` - `feat: improve bike gps test dashboard`
- `aae0dbc` - `feat: improve field tracking and map labels`
- `dcfaa9c` - `fix: keep bike dashboard screen awake`
- `59c2c93` - `docs: document major mobile bike gps update`
- `afedf0b` - `fix: hide bike speed before active rental`
- `3e156aa` - `fix: keep demo bike map data in lombok`

Pekerjaan yang tercatat:
- Menambahkan ringkasan dashboard pada `mobile_bike`.
- Mengarahkan `mobile_bike` menjadi dashboard perangkat sepeda, bukan hanya simulator.
- Menambahkan setup Docker untuk backend dan web admin.
- Menyesuaikan domain dan port deploy untuk `ikydev.site`.
- Memperbaiki Docker backend agar memakai PHP 8.4 sesuai dependency Laravel.
- Memperbaiki masalah `APP_KEY` Docker yang kosong atau tergabung ganda.
- Memaksa HTTPS saat aplikasi berjalan di balik Cloudflare Tunnel.
- Menggabungkan polish UI/UX admin dari Ahmad Zaki ke `main`.
- Memperbaiki permission GPS pada dashboard `mobile_bike`.
- Membuat tracking GPS otomatis aktif pada dashboard `mobile_bike`.
- Menyempurnakan dashboard testing GPS untuk kebutuhan uji langsung di HP.
- Menambahkan label peta dan tracking lapangan agar konsep lokasi sepeda lebih jelas.
- Membuat layar dashboard `mobile_bike` tetap hidup saat dipakai sebagai speedometer.
- Membuat dokumentasi update besar `mobile_bike`.
- Menyembunyikan kecepatan sebelum rental aktif supaya sepeda tidak terlihat berjalan saat belum disewa.
- Memindahkan data demo sepeda ke area Lombok agar peta admin tidak membuka lokasi yang tidak relevan.
- Menambahkan fallback dan filter lokasi Lombok untuk data demo agar peta admin lebih stabil.

## Ringkasan Per Fitur

### Fondasi Project

Penanggung jawab utama: msaririzki

Hasil:
- Repository awal.
- Backend API awal.
- `mobile_user`.
- `mobile_bike`.
- README setup.
- Koreksi identitas universitas.

### Active Rental

Penanggung jawab fitur: I Made Riki Widiastana Sanjaya

Hasil:
- Active Rental screen.
- API support untuk rental aktif.
- Data titik lokasi terakhir.
- Data kecepatan rental.
- Stabilitas live screen.
- Script development untuk menjalankan beberapa app.

Integrasi ke `main` dilakukan oleh msaririzki melalui merge branch `feature/active-rental-screen`.

### Live Map

Penanggung jawab fitur: Arya

Hasil:
- Live Map.
- Dynamic routing.
- Real-time GPS tracking.
- OSRM routing.
- UI map lebih rapi dan siap diintegrasikan ke Active Rental.

Integrasi ke `main` dilakukan oleh msaririzki melalui merge branch `feature/live-map`.

### Idle Warning UI

Penanggung jawab fitur: Adi Saputra

Hasil:
- Dialog idle warning.
- Status badge.
- API `continueIdle`.
- Integrasi idle warning ke Active Rental.

Integrasi ke `main` dilakukan oleh msaririzki melalui merge branch `feature/idle-warning-ui`.

### Simulator dan Mobile Bike

Penanggung jawab fitur awal: Ahmad Jul Hadi

Hasil dari Ahmad Jul Hadi:
- Manual GPS input.
- Mock route simulation.
- Preset lokasi.
- Interval control.
- Mode indicator.
- Terjemahan bahasa Indonesia dan perbaikan syntax simulator.

Pengembangan lanjutan oleh msaririzki:
- Dashboard perangkat sepeda.
- Real GPS permission.
- Auto start GPS tracking.
- Mini map atau tampilan jalur pada dashboard.
- Screen awake untuk penggunaan seperti speedometer.
- Kecepatan hanya tampil saat rental aktif.
- Dokumentasi update besar mobile_bike.

### Rental History

Penanggung jawab fitur: Endah Komariah Lestari

Hasil:
- Rental History.
- Detail rental.
- Filter status.
- Filter periode.
- Dashboard history premium.
- Health metrics.
- Journey highlight.
- Shortcut UX ke beranda.

Integrasi dan pembersihan merge dilakukan oleh msaririzki.

### UI Polish Mobile

Penanggung jawab fitur: Anggil

Hasil:
- Setup branch UI polish.
- Folder splash.
- Sinkronisasi branch dengan `main`.

Catatan:
- Dari histori `main`, kontribusi Anggil yang tercatat lebih banyak pada setup dan sinkronisasi branch. Detail polish visual lanjutan tidak terlihat sebagai commit feature terpisah di histori `main`.

### Web Admin Monitoring

Penanggung jawab awal dan integrasi: msaririzki

Hasil:
- Web admin monitoring sepeda.
- Dashboard admin awal.
- Data sepeda, status, baterai, lokasi, dan monitoring rental.
- Docker deploy untuk backend dan admin.
- Domain deploy `bike.ikydev.site`.
- Perbaikan HTTPS di balik Cloudflare Tunnel.
- Data demo sepeda dipusatkan ke area Lombok.

### UI/UX Web Admin

Penanggung jawab polish: Ahmad Zaki Aldrin

Hasil:
- Dashboard admin dipoles menjadi lebih modern.
- Bahasa UI dibuat lebih Indonesia.
- Dashboard dibuat lebih interaktif.
- Analytics ditambahkan.
- Navigasi dibuat responsif.
- Hasil polish digabung ke `main` pada commit `15be0eb`.

## Catatan Data NIM

NIM yang sudah tercatat:
- Ahmad Zaki Aldrin: 2301010023

NIM yang belum ditemukan di histori Git atau dokumen lokal:
- msaririzki
- I Made Riki Widiastana Sanjaya
- Arya
- Adi Saputra
- Ahmad Jul Hadi
- Endah Komariah Lestari
- Anggil

Jika dosen meminta NIM semua anggota, data NIM perlu dilengkapi manual oleh tim agar dokumen ini bisa dibuat final sepenuhnya.

## Status Akhir Sampai 12 Mei 2026

Project sudah memiliki:
- Backend API Laravel.
- Aplikasi `mobile_user`.
- Aplikasi `mobile_bike`.
- Active rental.
- Live map.
- Idle warning.
- Rental history.
- Web admin monitoring.
- UI/UX admin yang sudah dipoles.
- Dashboard perangkat sepeda dengan real GPS.
- Setup Docker untuk deploy server.
- Konfigurasi domain publik `bike.ikydev.site`.
- Data demo sepeda yang diarahkan ke area Lombok.

