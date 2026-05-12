# Catatan Server Ikydev - Deploy Smart Bike Backend

Domain: `ikydev.site`  
Backend/API/Admin: `https://bike.ikydev.site`  
Admin URL: `https://bike.ikydev.site/admin`  
API URL untuk mobile: `https://bike.ikydev.site/api`

---

## Cek Port Server

Port yang sudah terlihat aktif di server:

```text
8001 -> e-mas-kapor-web-1
8003 -> prikotes-web-1
8010 -> fyt-web
3307 -> e-mas-kapor-db-1
```

Port Smart Bike diset agar tidak bentrok:

```text
8005 -> smart-bike web/nginx
3311 -> smart-bike MariaDB external
```

Cloudflare Tunnel untuk `bike.ikydev.site` diarahkan ke:

```text
http://localhost:8005
```

---

## Yang Dilakukan di Server

### 1. Install kebutuhan server

Di server Linux:

```bash
sudo apt update
sudo apt install -y git curl ca-certificates
```

Install Docker dan Docker Compose plugin sesuai distro server.

Cek:

```bash
docker --version
docker compose version
```

---

### 2. Clone project

```bash
git clone https://github.com/msaririzki/smart-bike.git
cd smart-bike
```

Jika repo sudah ada:

```bash
cd smart-bike
git pull
```

---

### 3. Siapkan env Docker

Copy template:

```bash
cp deploy/ikydev/root.env.example .env
```

Edit:

```bash
nano .env
```

Wajib ganti:

```env
DB_PASSWORD=GANTI_PASSWORD_DATABASE_YANG_KUAT
MYSQL_ROOT_PASSWORD=GANTI_PASSWORD_ROOT_DATABASE_YANG_KUAT
```

Jika deploy pertama dan ingin data demo/default:

```env
RUN_SEED_ON_DEPLOY=true
```

Setelah deploy pertama berhasil, ubah kembali:

```env
RUN_SEED_ON_DEPLOY=false
```

---

### 4. Siapkan env Laravel backend

Copy template:

```bash
cp deploy/ikydev/backend.env.example backend/.env
```

Edit:

```bash
nano backend/.env
```

Pastikan:

```env
APP_URL=https://bike.ikydev.site
APP_ENV=production
APP_DEBUG=false

DB_HOST=db
DB_DATABASE=smart_bike_rental
DB_USERNAME=smart_bike
DB_PASSWORD=sama_dengan_DB_PASSWORD_di_root_env
```

`APP_KEY` boleh kosong saat deploy pertama. Container akan menjalankan `php artisan key:generate --force`.

---

### 5. Jalankan Docker

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
docker compose logs -f db
```

Tes lokal di server:

```bash
curl -I http://localhost:8005
curl -I http://localhost:8005/admin
```

---

### 6. Setup Cloudflare Tunnel

Di Cloudflare Zero Trust:

1. Buat tunnel baru.
2. Install connector `cloudflared` di server, atau gunakan service `cloudflared` dari Docker Compose.
3. Buat Public Hostname:

```text
Subdomain: api
Domain: ikydev.site
Service: http://localhost:8005
```

Hasil akhirnya:

```text
https://bike.ikydev.site
```

Admin:

```text
https://bike.ikydev.site/admin
```

API:

```text
https://bike.ikydev.site/api
```

---

### 7. Build Mobile ke HP

Untuk `mobile_user`:

```bash
cd mobile_user
flutter build apk --dart-define=API_BASE_URL=https://bike.ikydev.site/api
```

Untuk `mobile_bike`:

```bash
cd mobile_bike
flutter build apk --dart-define=API_BASE_URL=https://bike.ikydev.site/api
```

Kalau testing langsung:

```bash
flutter run --dart-define=API_BASE_URL=https://bike.ikydev.site/api
```

---

## Akun Demo Jika Seeder Dijalankan

Jika `RUN_SEED_ON_DEPLOY=true`, akun demo yang tersedia:

```text
superadmin@smartbike.test / password
admin@smartbike.test / password
user@smartbike.test / password
device@smartbike.test / password
```

Untuk server publik, segera ganti password atau buat akun baru.

---

## Perintah Update Berikutnya

Setiap ada update kode:

```bash
cd smart-bike
git pull
docker compose up -d --build
```

Clear cache manual jika perlu:

```bash
docker compose exec app php artisan optimize:clear
docker compose exec app php artisan optimize
```

Jalankan migrate manual jika perlu:

```bash
docker compose exec app php artisan migrate --force
```

---

## Backup Database

Backup:

```bash
docker compose exec db mariadb-dump -u root -p smart_bike_rental > backup-smart-bike.sql
```

Restore:

```bash
docker compose exec -T db mariadb -u root -p smart_bike_rental < backup-smart-bike.sql
```

---

## Catatan Penting

- Jangan commit `.env` root.
- Jangan commit `backend/.env`.
- Jangan pakai `127.0.0.1` untuk APK HP.
- Untuk HP, selalu pakai:

```text
https://bike.ikydev.site/api
```

- Server tanpa IP publik tetap bisa dipakai karena Cloudflare Tunnel memakai koneksi keluar dari server ke Cloudflare.

