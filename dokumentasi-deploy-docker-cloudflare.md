# Dokumentasi Deploy Backend Smart Bike dengan Docker dan Cloudflare Tunnel

Tanggal: 12 Mei 2026  
Scope: backend Laravel, admin web, API mobile  
Mobile app: tetap dibuild ke HP dan diarahkan ke domain API

---

## Ringkasan

Backend dan admin sekarang bisa dijalankan dengan Docker.

Service yang tersedia:

- `app`: Laravel PHP-FPM
- `queue`: Laravel queue worker
- `web`: Nginx
- `db`: MariaDB
- `cloudflared`: opsional untuk Cloudflare Tunnel

Arsitektur deploy:

```text
HP mobile_user / mobile_bike
-> https://api.domainkamu.com
-> Cloudflare Tunnel
-> server tanpa IP publik
-> Nginx container
-> Laravel PHP-FPM container
-> MariaDB container
```

Server tidak wajib punya IP publik selama server bisa akses internet keluar.

---

## File Docker yang Ditambahkan

```text
docker-compose.yml
.env.docker.example
backend/.dockerignore
backend/docker/nginx/default.conf
backend/docker/php/Dockerfile
backend/docker/php/custom.ini
backend/docker/php/entrypoint.sh
```

---

## Persiapan Server

Install:

- Docker
- Docker Compose plugin
- Git

Clone repo:

```bash
git clone https://github.com/msaririzki/smart-bike.git
cd smart-bike
```

---

## Setup Environment

### 1. Buat `.env` Docker di root repo

```bash
cp .env.docker.example .env
```

Edit:

```env
COMPOSE_PROJECT_NAME=smart-bike
WEB_PORT=8001
DB_DATABASE=smart_bike_rental
DB_USERNAME=smart_bike
DB_PASSWORD=password_database_yang_kuat
MYSQL_ROOT_PASSWORD=password_root_yang_kuat
DB_PORT_EXTERNAL=3307
RUN_SEED_ON_DEPLOY=false
```

Catatan:

- `.env` di root dipakai oleh Docker Compose.
- Jangan commit file `.env`.

### 2. Buat `.env` Laravel

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```env
APP_NAME="Smart Bike Rental"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.domainkamu.com

DB_CONNECTION=mariadb
DB_HOST=db
DB_PORT=3306
DB_DATABASE=smart_bike_rental
DB_USERNAME=smart_bike
DB_PASSWORD=password_database_yang_kuat

SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database
```

`APP_KEY` boleh kosong saat pertama deploy. Entrypoint Docker akan menjalankan:

```bash
php artisan key:generate --force
```

---

## Menjalankan Backend

Build dan jalankan:

```bash
docker compose up -d --build
```

Cek container:

```bash
docker compose ps
```

Cek log:

```bash
docker compose logs -f app
docker compose logs -f web
```

Backend bisa diakses dari server:

```text
http://localhost:8001
```

Admin:

```text
http://localhost:8001/admin
```

API:

```text
http://localhost:8001/api
```

---

## Seeder Awal

Jika database masih kosong dan ingin membuat data demo/default:

1. Edit `.env` root:

```env
RUN_SEED_ON_DEPLOY=true
```

2. Jalankan ulang:

```bash
docker compose up -d --build
```

3. Setelah selesai, sebaiknya ubah lagi:

```env
RUN_SEED_ON_DEPLOY=false
```

Akun demo dari seeder:

```text
superadmin@smartbike.test / password
admin@smartbike.test / password
user@smartbike.test / password
device@smartbike.test / password
```

Untuk server publik, ganti password setelah login atau buat akun baru yang aman.

---

## Cloudflare Tunnel

Ada dua opsi.

### Opsi A: Cloudflared di Host

Ini paling umum dan mudah dikontrol.

Di Cloudflare Zero Trust:

1. Buat Tunnel.
2. Install `cloudflared` di server.
3. Jalankan connector sesuai command dari Cloudflare.
4. Tambahkan Public Hostname:

```text
Hostname: api.domainkamu.com
Service: http://localhost:8001
```

Mobile app nanti memakai:

```text
https://api.domainkamu.com/api
```

### Opsi B: Cloudflared via Docker Compose

Isi token di `.env` root:

```env
CLOUDFLARE_TUNNEL_TOKEN=token_dari_cloudflare
```

Jalankan:

```bash
docker compose --profile tunnel up -d
```

Public hostname di Cloudflare tetap diarahkan ke service:

```text
http://web:80
```

Namun jika konfigurasi public hostname dilakukan dari dashboard Cloudflare, cukup pastikan tunnel connector aktif.

---

## Koneksi Mobile App ke Domain

Ya, `mobile_user` dan `mobile_bike` bisa konek ke domain.

Saat run/build Flutter, gunakan:

```bash
flutter run --dart-define=API_BASE_URL=https://api.domainkamu.com/api
```

Untuk build APK:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.domainkamu.com/api
```

Untuk `mobile_user`:

```bash
cd mobile_user
flutter build apk --dart-define=API_BASE_URL=https://api.domainkamu.com/api
```

Untuk `mobile_bike`:

```bash
cd mobile_bike
flutter build apk --dart-define=API_BASE_URL=https://api.domainkamu.com/api
```

Jangan pakai `127.0.0.1` untuk HP fisik karena itu mengarah ke HP sendiri, bukan server.

---

## Perintah Operasional

Update kode:

```bash
git pull
docker compose up -d --build
```

Masuk container app:

```bash
docker compose exec app bash
```

Jalankan artisan:

```bash
docker compose exec app php artisan route:list
docker compose exec app php artisan migrate --force
docker compose exec app php artisan optimize:clear
docker compose exec app php artisan optimize
```

Backup database:

```bash
docker compose exec db mariadb-dump -u root -p smart_bike_rental > backup-smart-bike.sql
```

Restore database:

```bash
docker compose exec -T db mariadb -u root -p smart_bike_rental < backup-smart-bike.sql
```

Stop:

```bash
docker compose down
```

Stop dan hapus volume database:

```bash
docker compose down -v
```

Hati-hati: `down -v` menghapus database.

---

## Catatan Production

Pastikan:

- `APP_ENV=production`
- `APP_DEBUG=false`
- password database kuat
- akun demo tidak dipakai untuk production final
- Cloudflare SSL aktif
- domain API sudah HTTPS
- backup database rutin

Jika API dipakai Flutter Web, cek konfigurasi CORS Laravel. Untuk Android/iOS native, CORS biasanya bukan masalah utama.

---

## Troubleshooting

### Container app gagal karena database timeout

Cek:

```bash
docker compose logs db
docker compose logs app
```

Pastikan password di `.env` root dan `backend/.env` sama.

### Admin tidak bisa dibuka

Cek:

```bash
docker compose ps
docker compose logs web
docker compose logs app
```

Buka:

```text
http://localhost:8001/admin
```

### Mobile tidak bisa konek

Pastikan app dibuild dengan:

```text
--dart-define=API_BASE_URL=https://api.domainkamu.com/api
```

Pastikan endpoint bisa dibuka:

```text
https://api.domainkamu.com/api/bikes
```

Endpoint tertentu butuh login token, jadi response unauthenticated masih normal.
