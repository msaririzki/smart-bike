# Tutorial Update Branch Fitur Dari Main

Dokumen ini untuk teman-teman yang sedang mengerjakan branch fitur masing-masing, misalnya:

- `feature/active-rental-screen`
- `feature/live-map`
- `feature/idle-warning-ui`
- `feature/simulator-enhancement`
- `feature/rental-history`
- `feature/ui-polish`
- `feature/admin-ui-ux-polish`

Tujuannya: branch fitur kalian harus selalu mengambil update terbaru dari `main`, supaya tidak ketinggalan kode dan tidak banyak conflict saat mau merge.

## Aturan Penting

1. Jangan kerja langsung di `main`.
2. Jangan pakai `git reset --hard` kecuali benar-benar paham dan sudah izin ke lead.
3. Jangan hapus file orang lain saat conflict.
4. Sebelum update dari `main`, pastikan pekerjaan kalian aman dulu dengan commit atau stash.
5. Setelah merge dari `main`, wajib test ulang fitur kalian.

## Cara Cek Posisi Saat Ini

Jalankan:

```bash
git status
git branch
```

Pastikan kalian sedang di branch fitur kalian, bukan `main`.

Contoh output yang benar:

```text
* feature/idle-warning-ui
  main
```

Kalau yang aktif `main`, pindah dulu ke branch fitur:

```bash
git checkout feature/nama-branch-kalian
```

Contoh:

```bash
git checkout feature/idle-warning-ui
```

## Jika Branch Belum Ada Di Laptop

Kalau branch kalian ada di GitHub tapi belum ada di laptop:

```bash
git fetch origin
git checkout -b feature/nama-branch-kalian origin/feature/nama-branch-kalian
```

Contoh:

```bash
git fetch origin
git checkout -b feature/idle-warning-ui origin/feature/idle-warning-ui
```

## Langkah Aman Update Branch Dari Main

Pakai langkah ini setiap kali ingin mengambil update terbaru dari `main`.

### 1. Cek Perubahan Lokal

```bash
git status
```

Kalau muncul file merah atau hijau, berarti ada perubahan yang belum aman.

Jika pekerjaan sudah layak disimpan:

```bash
git add .
git commit -m "wip: simpan progress sebelum update main"
```

Jika belum mau commit, pakai stash:

```bash
git stash push -m "wip sebelum update main"
```

### 2. Ambil Data Terbaru Dari GitHub

```bash
git fetch origin
```

### 3. Update Branch Main Lokal

```bash
git checkout main
git pull origin main
```

### 4. Balik Ke Branch Fitur

```bash
git checkout feature/nama-branch-kalian
```

Contoh:

```bash
git checkout feature/idle-warning-ui
```

### 5. Gabungkan Main Ke Branch Fitur

```bash
git merge main
```

Kalau tidak ada conflict, Git biasanya langsung membuat merge commit atau memberi pesan sudah berhasil.

### 6. Jika Tadi Pakai Stash

Kalau pada langkah awal kalian memakai `git stash`, balikin perubahan kalian:

```bash
git stash pop
```

Jika muncul conflict setelah `stash pop`, selesaikan conflict seperti bagian berikutnya.

## Cara Mengatasi Conflict

Conflict biasanya muncul dengan pesan seperti:

```text
CONFLICT (content): Merge conflict in nama_file.dart
Automatic merge failed; fix conflicts and then commit the result.
```

Langkahnya:

1. Buka file yang conflict di VS Code.
2. Cari tanda seperti ini:

```text
<<<<<<< HEAD
kode dari branch kalian
=======
kode dari main
>>>>>>> main
```

3. Pilih kode yang benar. Kadang harus digabung, bukan pilih salah satu.
4. Hapus semua tanda conflict:

```text
<<<<<<<
=======
>>>>>>>
```

5. Setelah selesai, jalankan:

```bash
git status
git add .
git commit
```

Kalau editor commit terbuka dan kalian bingung, tutup saja setelah simpan pesan commit. Atau pakai:

```bash
git commit -m "merge main into feature branch"
```

## Setelah Merge Dari Main

Jalankan test sesuai bagian yang kalian kerjakan.

### Untuk Mobile User

```bash
cd mobile_user
flutter pub get
flutter analyze
flutter test
```

### Untuk Mobile Bike

```bash
cd mobile_bike
flutter pub get
flutter analyze
flutter test
```

### Untuk Backend Laravel

```bash
cd backend
composer install
php artisan test tests/Feature
```

Jika di Windows test backend error karena `APP_KEY`, jalankan:

```bash
set APP_KEY=base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
php artisan test tests/Feature
```

Jika di PowerShell:

```powershell
$env:APP_KEY="base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
php artisan test tests/Feature
```

## Push Branch Setelah Berhasil

Kalau merge dari `main` sudah selesai dan test sudah aman:

```bash
git push origin feature/nama-branch-kalian
```

Contoh:

```bash
git push origin feature/idle-warning-ui
```

## Contoh Lengkap

Misalnya Adi sedang di branch `feature/idle-warning-ui`.

```bash
git status
git add .
git commit -m "wip: update idle warning sebelum sync main"

git fetch origin
git checkout main
git pull origin main

git checkout feature/idle-warning-ui
git merge main

cd mobile_user
flutter pub get
flutter analyze
flutter test

cd ..
git push origin feature/idle-warning-ui
```

## Kalau Tidak Mau Commit Dulu

Pakai stash:

```bash
git status
git stash push -m "wip idle warning sebelum sync main"

git fetch origin
git checkout main
git pull origin main

git checkout feature/idle-warning-ui
git merge main

git stash pop
```

Setelah itu cek ulang:

```bash
git status
```

Jika aman:

```bash
git add .
git commit -m "feat: lanjutkan pengerjaan setelah sync main"
git push origin feature/idle-warning-ui
```

## Prompt Untuk AI

Kalau kalian memakai AI untuk membantu update branch dari `main`, kirim prompt ini:

```text
Saya sedang mengerjakan project Smart Bike Rental.
Saya berada di branch: feature/nama-branch-saya.

Tolong bantu saya mengambil update terbaru dari branch main ke branch saya.
Jangan hapus pekerjaan saya.
Jangan pakai git reset --hard.
Jika ada conflict, jelaskan file mana yang conflict dan bantu gabungkan kode dengan aman.
Setelah merge, bantu jalankan test sesuai bagian yang saya kerjakan.

Langkah yang saya inginkan:
1. Cek git status.
2. Kalau ada perubahan lokal, bantu commit WIP atau stash.
3. Fetch origin.
4. Checkout main dan pull origin main.
5. Checkout lagi ke branch fitur saya.
6. Merge main ke branch fitur saya.
7. Selesaikan conflict jika ada.
8. Jalankan analyze/test.
9. Push branch fitur saya ke GitHub.
```

Ganti `feature/nama-branch-saya` dengan branch kalian sendiri.

## Prompt Jika Ada Conflict

```text
Saat merge main ke branch fitur saya, muncul conflict.
Tolong bantu cek file yang conflict.
Jangan menghapus fitur dari main dan jangan menghapus pekerjaan saya.
Gabungkan keduanya dengan aman, lalu jelaskan perubahan yang dibuat.
Setelah itu jalankan analyze/test yang relevan.
```

## Prompt Jika Branch Tertinggal Jauh Dari Main

```text
Branch fitur saya tertinggal beberapa commit dari main.
Tolong bantu sinkronkan branch ini dengan main terbaru.
Pastikan perubahan terbaru di main tetap ada.
Pastikan fitur saya tetap ada.
Jangan merge file lock atau dependency yang tidak perlu jika tidak berhubungan dengan fitur saya.
Setelah selesai, jalankan test dan beri ringkasan apakah branch aman untuk merge ke main.
```

## Checklist Sebelum Minta Merge Ke Main

Sebelum bilang ke lead bahwa branch siap merge, pastikan:

- `git status` bersih.
- Branch sudah mengambil update terbaru dari `main`.
- Tidak ada conflict tersisa.
- `flutter analyze` lolos untuk app yang diubah.
- `flutter test` lolos untuk app yang diubah.
- `php artisan test tests/Feature` lolos jika mengubah backend.
- Tidak ada file dependency atau lockfile berubah tanpa alasan.
- Tidak ada file dokumentasi lama ikut masuk tanpa sengaja.
- Branch sudah dipush ke GitHub.

## Catatan Untuk Project Ini

Karena project ini punya beberapa bagian, test sesuai area kerja:

- Jika mengubah `mobile_user`, test `mobile_user`.
- Jika mengubah `mobile_bike`, test `mobile_bike`.
- Jika mengubah `backend`, test backend Laravel.
- Jika hanya mengubah dokumentasi `.md`, cukup cek isi file dan `git diff --check`.

Kalau branch kalian menambah banyak file yang bukan bagian tugas kalian, tanyakan dulu sebelum push. Contohnya, branch idle warning seharusnya tidak perlu mengubah file besar di `mobile_bike` kecuali memang ada alasan teknis.

