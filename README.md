# Smart Bike

Prototipe smart bike rental berbasis mobile computing.

Backend awal sudah tersedia di folder `backend` menggunakan Laravel, Sanctum API, SQLite/MySQL-ready migrations, seed demo, service layer billing/GPS/idle detection, dan admin Blade sederhana.

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
