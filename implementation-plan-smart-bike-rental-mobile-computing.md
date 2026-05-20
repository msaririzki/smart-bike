# IMPLEMENTATION PLAN
## Smart Bike Rental Berbasis Mobile Computing

## 1. Ringkasan Proyek

Proyek ini adalah prototipe sistem penyewaan sepeda pintar berbasis **mobile computing**, di mana sepeda bertindak sebagai **terminal bergerak** yang terus mengirim data ke server melalui **jaringan seluler** saat berpindah lokasi dan berpindah cakupan **BTS**.

Pada implementasi ini, perangkat IoT pada sepeda tidak menggunakan hardware khusus, tetapi menggunakan **smartphone sebagai simulator IoT**. Smartphone tersebut berfungsi untuk:

- mengambil koordinat GPS
- mendeteksi pergerakan
- mengirim data lokasi secara periodik
- mengirim status koneksi
- mengirim status sepeda
- mendukung perhitungan biaya berbasis jarak

Sistem juga memiliki logika **idle detection**, yaitu jika sepeda tidak bergerak selama periode tertentu, user akan menerima peringatan. Jika user tetap melanjutkan sewa tanpa bergerak, sistem tetap memotong biaya dengan tarif idle yang lebih kecil.

---

## 2. Tujuan Proyek

### 2.1 Tujuan Umum

Membangun prototipe sistem penyewaan sepeda pintar yang menunjukkan penerapan konsep mobile computing secara nyata melalui:

- terminal bergerak
- komunikasi nirkabel real-time
- sinkronisasi data antara perangkat bergerak, server, dan user
- pengolahan lokasi menjadi jarak tempuh
- billing dinamis berbasis jarak
- context awareness melalui deteksi idle

### 2.2 Tujuan Khusus

Sistem harus mampu:

- menampilkan sepeda yang tersedia
- memulai dan mengakhiri sewa
- memantau lokasi sepeda secara real-time
- menghitung jarak tempuh berdasarkan data GPS
- menghitung biaya utama berdasarkan jarak
- mendeteksi sepeda diam selama batas waktu tertentu
- memberi peringatan saat idle
- menambahkan biaya idle jika user tetap diam
- memungkinkan superadmin mengubah parameter billing dan movement threshold

---

## 3. Nilai Mobile Computing

Sistem ini benar-benar termasuk mobile computing karena memiliki unsur berikut:

- **mobility**: sepeda sebagai terminal bergerak
- **wireless communication**: komunikasi memakai data seluler
- **network continuity**: koneksi tetap berjalan walau berpindah cakupan BTS
- **real-time synchronization**: data dikirim terus ke server
- **location awareness**: sistem menggunakan GPS
- **context awareness**: sistem membedakan kondisi bergerak dan idle
- **dynamic computing**: biaya dihitung berdasarkan kondisi aktual penggunaan

---

## 4. Stack Teknologi

### 4.1 Frontend Mobile
**Flutter**

Digunakan untuk membangun:
- aplikasi user
- aplikasi simulator sepeda
- panel admin sederhana bila diperlukan mobile/web hybrid

Alasan:
- satu codebase
- cepat untuk prototipe
- cocok untuk real-time mobile app

### 4.2 Backend
Disarankan 2 opsi. Pilih salah satu.

#### Opsi A — Firebase Stack
- Firebase Authentication
- Firebase Realtime Database
- Firebase Cloud Functions

Cocok jika ingin:
- cepat jadi
- real-time sederhana
- minim konfigurasi server

#### Opsi B — Laravel + MySQL + WebSocket/Realtime
- Laravel API
- MySQL
- Laravel Sanctum / Passport
- Laravel Queue
- Pusher / Soketi / Laravel Reverb

Cocok jika ingin:
- struktur backend lebih formal
- rule bisnis lebih fleksibel
- panel admin lebih nyaman
- lebih cocok untuk Codex jika memang sering pakai Laravel

### 4.3 Map
- OpenStreetMap
- `flutter_map`

### 4.4 GPS dan Device Utilities
- `geolocator`
- `connectivity_plus`
- `permission_handler`
- `shared_preferences`

### 4.5 Notifikasi
- local in-app notification
- atau Firebase Cloud Messaging jika dibutuhkan

---

## 5. Rekomendasi Stack Final

Karena implementasi akan dibantu Codex, stack yang direkomendasikan adalah:

### Mobile
- Flutter

### Backend
- Laravel 12/13
- MySQL
- Laravel Sanctum
- Laravel Queue
- Laravel Reverb atau Pusher-compatible realtime
- Redis opsional

### Map
- OpenStreetMap + flutter_map

### Kenapa Laravel?
- rule bisnis billing lebih mudah dikelola
- superadmin settings lebih mudah dibuat
- panel admin bisa dibuat rapi
- lebih fleksibel untuk logika idle dan pricing
- cocok untuk implementasi sistem role user/admin/superadmin

Kalau mau cepat sekali, Firebase bisa dipilih. Tapi kalau ingin **arsitektur rapi dan fleksibel untuk Codex**, Laravel lebih cocok.

---

## 6. Arsitektur Sistem

Sistem terdiri dari 4 komponen utama:

### 6.1 User App
Aplikasi yang digunakan pelanggan untuk:
- login/register
- melihat sepeda tersedia
- mulai sewa
- memantau rental aktif
- melihat lokasi sepeda
- melihat total jarak
- melihat biaya berjalan
- menerima peringatan idle
- memilih lanjut atau akhiri sewa
- melihat histori transaksi

### 6.2 Bike Simulator App
Aplikasi pada HP kedua yang bertindak sebagai perangkat sepeda:
- login sebagai device
- memilih bike yang diwakili
- mengirim GPS berkala
- mengirim status jaringan seluler
- mengirim status sepeda
- mengirim data movement
- mengirim heartbeat ke server

### 6.3 Backend Server
Bertanggung jawab untuk:
- autentikasi
- manajemen user, admin, superadmin
- manajemen bike
- rental lifecycle
- hitung jarak
- hitung biaya berbasis jarak
- deteksi idle
- pengiriman warning/status
- histori rental
- konfigurasi parameter sistem

### 6.4 Admin Panel
Digunakan oleh superadmin/admin untuk:
- kelola bike
- kelola user
- ubah tarif
- ubah threshold jarak
- ubah aturan idle
- ubah parameter biaya idle
- melihat log rental
- melihat statistik penggunaan

---

## 7. Role dan Hak Akses

### 7.1 User
Bisa:
- register/login
- melihat bike tersedia
- mulai rental
- melihat bike yang sedang disewa
- menerima warning idle
- menyelesaikan sewa
- melihat histori pribadi

### 7.2 Admin
Bisa:
- melihat data user
- melihat data bike
- melihat rental aktif
- melihat histori
- monitoring operasional

Tidak bisa:
- mengubah global billing setting sensitif jika dibatasi

### 7.3 Superadmin
Bisa:
- semua hak admin
- mengubah tarif
- mengubah movement threshold
- mengubah interval GPS
- mengubah aturan idle warning
- mengubah biaya idle
- mengubah formula biaya aktif
- mengubah parameter minimum movement
- mengaktifkan/nonaktifkan fitur tertentu

### 7.4 Device / Bike Simulator
Bisa:
- login sebagai device
- mengirim lokasi
- mengirim status bike
- mengirim heartbeat
- membaca data pairing sepeda yang diwakili

Tidak bisa:
- mengakses data admin/user umum

---

## 8. Konsep Bisnis Baru

### 8.1 Biaya Utama
Biaya utama dihitung berdasarkan **jarak tempuh aktual**.

### 8.2 Idle Logic
Jika sepeda tidak bergerak selama periode tertentu:
- sistem memberi warning
- user ditanya apakah ingin lanjut atau akhiri
- jika lanjut namun tetap diam, sistem mengenakan **biaya idle** kecil
- jika user akhiri, sewa selesai

### 8.3 Alasan Model Ini Kuat
- lebih “computing” karena sistem harus hitung jarak nyata
- lebih realistis karena membedakan kondisi bergerak dan diam
- lebih adil dari sisi bisnis
- lebih menarik saat dipresentasikan

---

## 9. Aturan Pricing yang Harus Fleksibel

Semua ini harus bisa diubah oleh superadmin melalui panel setting.

### 9.1 Parameter Global
- `distance_unit_meters`
- `distance_price_amount`
- `idle_warning_after_seconds`
- `idle_billing_interval_seconds`
- `idle_billing_amount`
- `minimum_movement_threshold_meters`
- `gps_update_interval_seconds`
- `offline_timeout_seconds`
- `max_gps_accuracy_meters`
- `grace_period_before_idle_billing_seconds`

### 9.2 Contoh Default
- `distance_unit_meters = 100`
- `distance_price_amount = 500`
- `idle_warning_after_seconds = 300`
- `idle_billing_interval_seconds = 300`
- `idle_billing_amount = 200`
- `minimum_movement_threshold_meters = 10`
- `gps_update_interval_seconds = 5`
- `offline_timeout_seconds = 20`
- `max_gps_accuracy_meters = 25`
- `grace_period_before_idle_billing_seconds = 60`

### 9.3 Tujuan Threshold
Agar sistem fleksibel:
- kampus kecil bisa set lebih rendah
- area besar bisa set lebih tinggi
- tarif bisa disesuaikan kapan saja tanpa ubah kode

---

## 10. Aturan Perhitungan Jarak

### 10.1 Prinsip Dasar
Sistem tidak boleh langsung menghitung semua perubahan GPS sebagai pergerakan valid.

Karena GPS bisa bergeser sedikit walaupun user diam.

### 10.2 Solusi
Gunakan **minimum movement threshold**.

Jika perpindahan antar titik GPS:
- `< threshold`, dianggap noise / tidak dihitung sebagai movement valid
- `>= threshold`, dihitung sebagai movement valid

### 10.3 Formula Jarak
Hitung jarak antar dua koordinat menggunakan **Haversine formula**.

### 10.4 Akumulasi Jarak
Total jarak rental = jumlah semua segmen movement valid.

### 10.5 Aturan Akurasi
Jika data GPS punya accuracy terlalu buruk:
- bisa diabaikan
- atau disimpan tapi tidak dihitung ke billing

Contoh:
- jika accuracy > 25 meter, jangan dipakai untuk billing

---

## 11. Aturan Deteksi Idle

### 11.1 Definisi Idle
Idle adalah kondisi ketika sepeda **tidak mengalami pergerakan valid** selama durasi tertentu.

### 11.2 Contoh
Jika selama 300 detik terakhir tidak ada segmen movement valid, status menjadi `idle_warning`.

### 11.3 Tahapan Idle
#### State 1 — Active Moving
Sepeda masih bergerak normal.

#### State 2 — Idle Warning
Setelah diam lebih dari batas waktu:
- kirim warning ke user
- tampilkan opsi:
  - lanjut sewa
  - akhiri sewa

#### State 3 — Idle Billing
Jika user memilih lanjut atau tidak merespons dalam batas waktu tertentu:
- rental tetap aktif
- biaya idle dikenakan per interval

#### State 4 — Rental Finished
Jika user memilih selesai, rental ditutup.

---

## 12. State Machine Rental

Gunakan status rental berikut:

- `pending`
- `active`
- `idle_warning`
- `idle_billing`
- `completed`
- `cancelled`

Gunakan status bike berikut:

- `available`
- `reserved`
- `in_use`
- `idle`
- `offline`
- `maintenance`

---

## 13. Flow Sistem Lengkap

### 13.1 Flow Start Rental
1. user login
2. user pilih bike tersedia
3. server validasi bike available
4. server buat rental baru
5. bike status berubah jadi `in_use`
6. rental status jadi `active`
7. bike simulator mulai stream data

### 13.2 Flow GPS Update
1. simulator kirim:
   - latitude
   - longitude
   - speed
   - accuracy
   - timestamp
   - network type
   - signal info jika ada
2. server simpan location point
3. server hitung jarak dari titik sebelumnya
4. jika valid, tambah total distance
5. server hitung cost berdasarkan unit distance
6. update dashboard user

### 13.3 Flow Idle Warning
1. server cek tidak ada movement valid selama 300 detik
2. rental status jadi `idle_warning`
3. user menerima peringatan
4. user diberi 2 pilihan:
   - lanjut
   - akhiri

### 13.4 Flow Continue After Warning
1. user pilih lanjut
2. rental status jadi `idle_billing`
3. selama tetap diam:
   - billing idle berjalan per interval
4. jika bergerak lagi:
   - status balik ke `active`

### 13.5 Flow Finish Rental
1. user pilih selesai
2. server hitung final:
   - total distance
   - distance cost
   - idle cost
   - total cost
3. rental status jadi `completed`
4. bike status kembali `available`

---

## 14. Struktur Modul Backend

### 14.1 Auth Module
- login user
- login admin
- login superadmin
- login device
- token authentication

### 14.2 User Module
- profile
- rental history
- active rental

### 14.3 Bike Module
- bike master data
- bike status
- bike assignment ke simulator
- bike availability

### 14.4 Rental Module
- create rental
- track active rental
- finish rental
- cancel rental
- idle transition

### 14.5 Location Processing Module
- receive GPS point
- validate GPS accuracy
- calculate distance
- determine movement validity
- update movement state

### 14.6 Billing Module
- distance-based pricing
- idle-based pricing
- pricing configuration
- billing summary generation

### 14.7 Notification Module
- idle warning
- offline warning
- state changes
- rental completion summary

### 14.8 Admin Setting Module
- tariff config
- movement threshold config
- idle config
- bike rules
- GPS rules

### 14.9 Reporting Module
- total rentals
- total distance
- total revenue simulation
- idle frequency
- top used bikes

---

## 15. Struktur Database yang Direkomendasikan

### 15.1 users
Kolom:
- id
- name
- email
- password
- role (`user`, `admin`, `superadmin`, `device`)
- phone
- created_at
- updated_at

### 15.2 bikes
Kolom:
- id
- code
- name
- status
- current_latitude
- current_longitude
- last_accuracy
- is_online
- battery_percent
- assigned_device_user_id
- last_seen_at
- created_at
- updated_at

### 15.3 rentals
Kolom:
- id
- user_id
- bike_id
- status
- started_at
- ended_at
- last_movement_at
- idle_warning_at
- idle_started_at
- total_distance_meters
- distance_cost
- idle_cost
- total_cost
- created_at
- updated_at

### 15.4 rental_location_points
Kolom:
- id
- rental_id
- bike_id
- latitude
- longitude
- speed_kmh
- accuracy_meters
- network_type
- movement_distance_meters
- is_valid_movement
- recorded_at
- created_at

### 15.5 rental_idle_events
Kolom:
- id
- rental_id
- event_type (`warning`, `continue`, `idle_billing_started`, `idle_billing_applied`, `resume_moving`)
- description
- event_at
- created_at

### 15.6 pricing_settings
Kolom:
- id
- key
- value
- value_type
- group_name
- description
- updated_by
- created_at
- updated_at

### 15.7 rental_billing_logs
Kolom:
- id
- rental_id
- billing_type (`distance`, `idle`)
- amount
- quantity
- unit_label
- notes
- created_at

### 15.8 device_heartbeats
Kolom:
- id
- bike_id
- device_user_id
- network_type
- last_seen_at
- signal_note nullable
- created_at
- updated_at

### 15.9 notifications
Kolom:
- id
- user_id
- rental_id nullable
- type
- title
- message
- is_read
- created_at
- updated_at

---

## 16. Model Pricing yang Harus Didukung

### 16.1 Model Distance Pricing
Formula dasar:

`distance_cost = floor(total_distance_meters / distance_unit_meters) * distance_price_amount`

Contoh:
- total_distance = 550 meter
- unit = 100 meter
- harga = Rp500
- chargeable units = floor(550 / 100) = 5
- cost = 5 × 500 = Rp2.500

### 16.2 Alternatif Partial Unit
Bisa juga gunakan ceil jika ingin semua meter terhitung.

Karena harus fleksibel, superadmin harus bisa memilih:
- `rounding_mode = floor`
- `rounding_mode = ceil`
- `rounding_mode = nearest`

### 16.3 Idle Billing
Jika rental masuk state `idle_billing`, maka:

`idle_cost += idle_billing_amount`

setiap `idle_billing_interval_seconds`

Contoh:
- idle interval = 300 detik
- idle amount = Rp200
- diam 15 menit
- idle cost = Rp600

### 16.4 Total Cost
`total_cost = distance_cost + idle_cost`

---

## 17. Logika Validasi Movement

Server harus punya fungsi seperti ini:

### 17.1 Input
- previous point
- current point
- threshold meter
- max accuracy meter

### 17.2 Output
- valid/invalid movement
- segment distance meter

### 17.3 Rule
- jika accuracy GPS buruk, segment invalid
- jika distance < threshold, segment invalid
- jika timestamp aneh/mundur, ignore
- jika lonjakan sangat jauh dalam waktu singkat, tandai anomaly

### 17.4 Anomaly Guard
Tambahkan proteksi:
- jika kecepatan implisit > batas wajar sepeda, jangan hitung segment

Contoh:
- kalau segmen menunjukkan 300 meter dalam 3 detik, itu tidak realistis

Gunakan setting:
- `max_reasonable_speed_kmh`

---

## 18. Konfigurasi Superadmin yang Wajib Ada

Superadmin harus bisa mengubah ini dari panel admin:

### Group: Distance Billing
- distance unit meter
- price per unit
- rounding mode
- minimum billable distance optional
- maximum reasonable speed

### Group: Idle Rules
- idle warning threshold
- idle grace response time
- idle billing interval
- idle billing amount
- auto finish after long idle optional

### Group: GPS Rules
- GPS update interval
- minimum movement threshold
- maximum acceptable accuracy
- offline timeout

### Group: Bike Rental Rules
- allow multiple active rentals = false
- maximum rental duration optional
- force finish when offline too long optional

---

## 19. API Endpoint Plan

Kalau pakai Laravel API, struktur endpoint bisa seperti ini.

### Auth
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`

### Bikes
- `GET /api/bikes`
- `GET /api/bikes/{id}`
- `POST /api/admin/bikes`
- `PUT /api/admin/bikes/{id}`
- `PATCH /api/admin/bikes/{id}/status`

### Rentals
- `POST /api/rentals/start`
- `GET /api/rentals/active`
- `GET /api/rentals/history`
- `POST /api/rentals/{id}/finish`
- `POST /api/rentals/{id}/idle/continue`
- `POST /api/rentals/{id}/idle/finish`

### Device / Simulator
- `POST /api/device/location-update`
- `POST /api/device/heartbeat`
- `GET /api/device/current-assignment`

### Admin Settings
- `GET /api/admin/settings`
- `PUT /api/admin/settings`
- `GET /api/admin/pricing-preview`

### Monitoring
- `GET /api/admin/rentals/active`
- `GET /api/admin/rentals/{id}`
- `GET /api/admin/reports/summary`

---

## 20. Service Layer Laravel yang Disarankan

### 20.1 RentalService
Mengurus:
- start rental
- finish rental
- status transitions

### 20.2 LocationProcessingService
Mengurus:
- receive point
- validate movement
- calculate segment distance
- update total distance

### 20.3 BillingService
Mengurus:
- recalculate distance cost
- apply idle billing
- generate billing summary

### 20.4 IdleDetectionService
Mengurus:
- cek last movement
- trigger idle warning
- switch idle billing state
- resume active state

### 20.5 PricingConfigService
Mengurus:
- baca setting global
- cache config
- validasi config changes

### 20.6 NotificationService
Mengurus:
- in-app notification
- idle warning push
- status messages

### 20.7 BikeStatusService
Mengurus:
- update bike online/offline
- update availability
- update status from device heartbeat

---

## 21. Scheduler / Cron Jobs

Beberapa logic lebih baik dijalankan periodik.

### Job 1 — Check Idle Rentals
Jalan tiap 1 menit:
- cek rental active
- lihat `last_movement_at`
- jika lewat threshold, ubah ke `idle_warning`

### Job 2 — Apply Idle Billing
Jalan tiap 1 menit:
- cek rental `idle_billing`
- jika interval terpenuhi, tambah biaya idle

### Job 3 — Mark Offline Bikes
Jalan tiap 1 menit:
- cek `last_seen_at`
- jika terlalu lama tidak heartbeat, bike jadi offline

### Job 4 — Auto Resume Active
Jalan saat ada GPS valid movement:
- jika status `idle_warning` atau `idle_billing`, balik ke `active`

---

## 22. UI Plan Mobile App

### 22.1 User App Screens
#### Splash
- logo
- check auth

#### Login/Register
- email
- password

#### Home
- daftar bike
- status available/in_use/offline

#### Bike Detail
- map location
- current info
- button start rental

#### Active Rental Screen
- map live
- total distance
- distance cost
- idle cost
- total cost
- status
- idle warning modal jika muncul
- button finish rental

#### Rental History
- daftar histori
- detail per rental

### 22.2 Bike Simulator App Screens
#### Login Device
- login device

#### Assignment Screen
- bike assigned
- current status

#### Simulator Dashboard
- GPS coordinates
- speed
- accuracy
- network type
- last sent time
- total points sent
- start/stop stream

---

## 23. Admin Panel Plan

### 23.1 Dashboard
- total bikes
- active rentals
- completed rentals
- offline bikes
- total revenue simulation

### 23.2 Bike Management
- create/edit bike
- assign device
- status monitor

### 23.3 User Management
- list users
- role management

### 23.4 Pricing Settings
- distance pricing
- idle pricing
- threshold settings
- GPS rules

### 23.5 Rental Monitoring
- active rental list
- idle rentals
- billing logs
- route preview

### 23.6 Reports
- total rental count
- average distance
- average idle event
- most used bike

---

## 24. Edge Cases yang Harus Ditangani

### 24.1 GPS Noise
- jangan hitung movement kecil
- filter berdasarkan accuracy

### 24.2 User Diam Tapi GPS Drift
- gunakan threshold meter
- jangan billing distance dari drift kecil

### 24.3 Internet Putus
- bike marked offline setelah timeout
- rental tetap ada
- data bisa sync lagi saat online

### 24.4 Device Mati Mendadak
- heartbeat berhenti
- admin/user lihat status offline

### 24.5 User Tidak Menjawab Idle Warning
Pilih satu rule:
- otomatis masuk idle billing
atau
- otomatis finish setelah grace period

Saran: otomatis masuk idle billing, karena lebih realistis untuk demo

### 24.6 Lonjakan GPS Tak Masuk Akal
- validasi speed maksimum
- ignore anomaly point

---

## 25. Testing Plan

### 25.1 Unit Test
- Haversine calculation
- movement validation
- distance billing
- idle billing
- status transitions

### 25.2 Feature Test
- user start rental
- device send valid point
- billing updated
- idle triggered after 5 min
- user continue from idle
- finish rental

### 25.3 Integration Test
- user app + device + backend
- realtime update
- admin settings effect

### 25.4 Manual Scenario Test
#### Scenario A
User bergerak normal  
Expected:
- total distance naik
- distance cost naik
- no idle warning

#### Scenario B
User diam 5 menit  
Expected:
- idle warning muncul

#### Scenario C
User diam terus setelah continue  
Expected:
- idle billing bertambah

#### Scenario D
User bergerak lagi setelah idle  
Expected:
- status kembali active

#### Scenario E
Superadmin ubah threshold  
Expected:
- logika billing langsung pakai parameter baru untuk rental berikutnya

---

## 26. Tahapan Pengembangan

### Phase 1 — Foundation
- setup Laravel
- setup Flutter
- auth
- roles
- bike master
- admin settings table

### Phase 2 — Rental Basic
- start rental
- finish rental
- active rental view
- bike status

### Phase 3 — Device Tracking
- simulator app
- GPS stream
- heartbeat
- live map

### Phase 4 — Distance Computing
- haversine
- movement validation
- threshold logic
- distance accumulation
- distance billing

### Phase 5 — Idle Logic
- last movement tracking
- idle warning
- continue flow
- idle billing
- auto resume

### Phase 6 — Superadmin Flexibility
- settings UI
- update distance unit
- update threshold
- update idle rules
- pricing preview

### Phase 7 — Reports & Hardening
- billing logs
- history detail
- anomaly filtering
- tests
- UI polish

---

## 27. Data yang Ditampilkan ke User Saat Rental Aktif

Minimal tampilkan:
- bike code
- status rental
- map live
- latitude/longitude
- current speed
- total distance
- distance cost
- idle cost
- total cost
- network status
- last update time

Kalau idle warning muncul:
- tampilkan modal
- pesan:
  “Sepeda tidak bergerak selama 5 menit. Apakah ingin mengakhiri sewa atau tetap melanjutkan?”
- tombol:
  - `Akhiri Sewa`
  - `Lanjutkan`

---

## 28. Rekomendasi Logika Default Terbaik

Default pertama yang disarankan:

- update GPS tiap 5 detik
- movement threshold = 10 meter
- max accuracy = 25 meter
- idle warning = 5 menit
- idle billing = Rp200 per 5 menit
- distance billing = Rp500 per 100 meter
- rounding = floor
- max speed valid = 40 km/h

Kenapa ini bagus:
- cukup ketat untuk mengurangi noise
- cukup sederhana untuk dijelaskan
- realistis untuk prototipe

---

## 29. Pseudocode Core Logic

### 29.1 Process GPS Point

```text
receive location point
load active rental for bike
if no active rental: store monitoring only

validate gps accuracy
if invalid accuracy:
    store point as ignored
    return

previous_valid_point = last valid point in rental
if no previous_valid_point:
    store point
    update last_seen
    return

distance = calculate_haversine(previous_valid_point, current_point)

if distance < minimum_movement_threshold:
    mark point as no valid movement
    if now - rental.last_movement_at >= idle_warning_after:
        set rental status = idle_warning
        send notification
    return

if implied_speed > max_reasonable_speed:
    mark anomaly
    return

store valid movement point
rental.total_distance_meters += distance
rental.last_movement_at = now

distance_cost = pricing_formula(rental.total_distance_meters)
rental.distance_cost = distance_cost

if rental.status in [idle_warning, idle_billing]:
    rental.status = active

save rental
```

### 29.2 Idle Billing Job

```text
for each rental with status idle_billing:
    if current_time - last_idle_billing_at >= idle_billing_interval:
        rental.idle_cost += idle_billing_amount
        create billing log
        update last_idle_billing_at
```

---

## 30. Output yang Harus Dihasilkan Codex

Codex harus menghasilkan:

### Backend
- Laravel project
- migrations
- models
- seeders
- auth
- role middleware
- services
- controllers
- API routes
- scheduler jobs
- tests

### Mobile
- Flutter user app
- Flutter simulator app atau dual-mode app
- auth screen
- bike list
- active rental screen
- map screen
- device simulator dashboard
- API integration
- idle warning modal

### Admin
- web admin panel atau simple Flutter admin
- settings page
- bike management
- rental monitoring
- pricing configuration

---

## 31. Instruksi Penting untuk Codex

Gunakan prinsip berikut saat implementasi:

- semua rule bisnis jangan ditaruh di controller
- controller harus tipis
- logika perhitungan jarak ada di service khusus
- logika idle ada di service khusus
- setting global harus dibaca dari database, bukan hardcoded
- billing log wajib disimpan agar transparan
- harus ada pemisahan distance cost dan idle cost
- movement threshold harus configurable
- sistem harus tahan terhadap GPS noise
- semua status transition harus konsisten dan terdokumentasi

---

## 32. Kesimpulan Final

Versi terbaru proyek ini jauh lebih kuat karena:

- biaya dihitung dari jarak, bukan hanya waktu
- ada context-aware logic saat sepeda diam
- ada idle warning
- ada idle billing
- semua parameter billing bisa diatur superadmin
- benar-benar menunjukkan mobile computing + dynamic computing
