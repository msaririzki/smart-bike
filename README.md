# Smart Bike

Prototipe smart bike rental berbasis mobile computing.

Backend awal sudah tersedia di folder `backend` menggunakan Laravel, Sanctum API, SQLite/MySQL-ready migrations, seed demo, service layer billing/GPS/idle detection, dan admin Blade sederhana.

Flutter User App tersedia di folder `mobile_user`.

## Demo Admin

- URL lokal: `http://127.0.0.1:8000/admin/login`
- Superadmin: `superadmin@smartbike.test` / `password`
- Admin: `admin@smartbike.test` / `password`

## Backend Verification

```bash
cd backend
php artisan migrate:fresh --seed
php artisan test
php artisan serve --host=127.0.0.1 --port=8000
```

## User App

Jalankan backend dulu, lalu:

```bash
cd mobile_user
flutter pub get
flutter run
```

Default API app mengarah ke `http://127.0.0.1:8000/api`. Untuk Android emulator gunakan:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Untuk HP fisik, ganti host dengan IP laptop pada jaringan yang sama.
