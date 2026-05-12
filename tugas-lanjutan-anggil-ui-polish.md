# Tugas Lanjutan Anggil - UI Polish

Tanggal: 11 Mei 2026  
Anggota: Anggil  
Branch sebelumnya: `feature/ui-polish`  
Status: update terbaru sudah masuk ke `main`

---

## Kondisi Saat Ini

Update dari branch `feature/ui-polish` sudah digabung ke `main`.

Yang sudah tersedia:

- Splash screen baru di:
  - `mobile_user/lib/src/features/splash/splash_screen.dart`
- Dependency animasi sudah ditambahkan:
  - `flutter_animate`
- App sekarang menampilkan splash selama proses bootstrap session.
- `SmartBikeUserApp` sudah mengecek token session sebelum masuk ke:
  - `HomeScreen` jika user sudah login
  - `AuthScreen` jika user belum login
- Widget test sudah disesuaikan agar mengecek splash terlebih dahulu sebelum login screen tampil.

Catatan:

Saat ini area UI polish yang masuk masih sebatas splash screen. Screen lain seperti auth, home, active rental, history, dan idle warning belum banyak disentuh oleh branch ini.

---

## Tugas Lanjutan Prioritas Tinggi

### 1. Test Splash Screen di Alur Login dan Session

Tujuan:

memastikan splash screen tidak mengganggu alur masuk aplikasi.

Langkah:

1. Pull `main` terbaru.
2. Jalankan `mobile_user`.
3. Buka aplikasi dalam kondisi belum login.
4. Pastikan splash muncul sebentar.
5. Pastikan setelah splash, user diarahkan ke login screen.
6. Login sebagai user.
7. Tutup aplikasi lalu buka lagi.
8. Pastikan splash muncul sebentar.
9. Pastikan setelah splash, user langsung masuk ke Home.
10. Logout.
11. Tutup dan buka aplikasi lagi.
12. Pastikan user kembali ke login screen.

Kriteria selesai:

- Splash muncul saat app pertama dibuka.
- Splash tidak stuck.
- User belum login diarahkan ke login.
- User yang masih punya session diarahkan ke Home.
- Setelah logout, user tidak kembali otomatis ke Home.

---

### 2. Rapikan Durasi Splash

Saat ini splash memakai delay sekitar 2 detik.

Tugas:

- Pastikan durasi splash terasa cukup, tidak terlalu lama.
- Jika backend/session check cepat, splash tetap terlihat halus.
- Jika session check lambat, loading tetap terlihat wajar.

Kriteria selesai:

- Splash tidak terasa memaksa user menunggu terlalu lama.
- Tidak ada blank screen sebelum atau sesudah splash.
- Animasi tidak patah saat berpindah ke screen berikutnya.

Catatan:

Jika mau mengubah durasi, diskusikan dulu dengan tim. Jangan terlalu pendek sampai animasi tidak terlihat, dan jangan terlalu panjang sampai terasa menghambat.

---

### 3. Cegah Risiko `setState` Setelah Widget Tidak Aktif

Tujuan:

memastikan bootstrap session aman jika app berubah state dengan cepat.

Tugas:

- Cek method `_bootstrap()` di:
  - `mobile_user/lib/src/app.dart`
- Tambahkan guard `if (!mounted) return;` sebelum `setState()` jika diperlukan.

Kriteria selesai:

- Tidak ada warning/error saat app ditutup atau reload cepat.
- `flutter analyze` tetap bersih.

Contoh area yang perlu dicek:

```dart
final token = results[0];
if (!mounted) return;
setState(() {
  _isLoggedIn = token != null;
  _isLoading = false;
});
```

---

### 4. Polish Auth Screen

Tujuan:

membuat tampilan login/register terasa satu gaya dengan splash screen.

Area yang dicek:

- `mobile_user/lib/src/features/auth/auth_screen.dart`

Tugas:

- Samakan warna utama dengan splash:
  - teal
  - slate/dark accent secukupnya
- Rapikan spacing form.
- Rapikan tombol login/register.
- Tambahkan state loading yang jelas saat submit.
- Pastikan error message tetap terbaca.
- Pastikan keyboard tidak membuat layout overflow.

Kriteria selesai:

- Login screen terlihat konsisten dengan splash.
- Form tetap mudah digunakan.
- Tidak ada overflow di layar kecil.
- Error API tetap tampil jelas.

---

### 5. Polish Home Screen

Tujuan:

membuat home screen lebih siap sebagai dashboard user.

Area yang dicek:

- `mobile_user/lib/src/features/home/home_screen.dart`

Tugas:

- Rapikan header user/home.
- Rapikan card sepeda tersedia.
- Pastikan status active rental mudah terlihat.
- Pastikan tombol untuk mulai rental jelas.
- Pastikan menu Riwayat tetap ada.
- Jangan menghapus integrasi Active Rental dan Rental History.

Kriteria selesai:

- Home terasa rapi dan mudah dipindai.
- User bisa langsung tahu apakah ada rental aktif.
- Tombol utama tidak tenggelam oleh elemen dekoratif.
- Bottom navigation tetap berfungsi.

Catatan penting:

File `home_screen.dart` sudah sering disentuh beberapa branch. Jangan mengembalikan versi lama yang menghapus menu `Riwayat` atau akses ke Active Rental.

---

## Tugas Lanjutan Prioritas Sedang

### 6. Buat Komponen Style Kecil Jika Mulai Banyak Duplikasi

Tujuan:

menghindari style berulang di banyak screen.

Tugas:

Jika warna, spacing, atau card style mulai sering diulang, buat helper kecil di folder yang sesuai.

Contoh yang boleh dibuat:

- app color constants
- reusable section title
- reusable primary button
- reusable empty state

Kriteria selesai:

- Komponen tidak berlebihan.
- Hanya dibuat jika benar-benar dipakai lebih dari satu tempat.
- Tidak mengubah struktur app terlalu besar.

---

### 7. Polish Active Rental Screen Bersama Riki

Tujuan:

membuat screen rental aktif lebih enak dipakai tanpa merusak logic yang sudah ada.

Koordinasi dengan:

- Riki, pemilik `feature/active-rental-screen`

Area yang boleh dipoles:

- header status rental
- panel GPS
- metric distance/speed/cost
- tombol finish rental
- empty state saat koordinat belum tersedia

Kriteria selesai:

- Data penting tetap mudah dibaca.
- Map tidak terlalu kecil.
- Tombol finish tetap jelas.
- Idle warning dialog tetap berfungsi.
- Tidak ada logic polling yang berubah tanpa koordinasi.

---

### 8. Polish Rental History Bersama Endah

Tujuan:

membuat daftar dan detail riwayat lebih konsisten dengan UI app.

Koordinasi dengan:

- Endah, pemilik `feature/rental-history`

Area yang boleh dipoles:

- filter chips
- list card history
- detail summary
- empty state
- error state
- loading skeleton

Kriteria selesai:

- Filter mudah dipahami.
- List tetap ringkas.
- Detail rental tidak terlalu ramai.
- Label estimasi tetap jelas.
- Tidak ada perubahan format data API tanpa koordinasi.

---

### 9. Validasi Responsive di Ukuran Layar Kecil

Tujuan:

memastikan polish tidak hanya bagus di layar besar.

Ukuran yang wajib dites:

- emulator kecil
- emulator sedang
- web mobile width jika menjalankan Flutter web

Screen yang wajib dicek:

- splash
- auth
- home
- active rental
- rental history

Kriteria selesai:

- Tidak ada overflow kuning/hitam.
- Text tidak kepotong.
- Tombol masih mudah ditekan.
- Card tidak terlalu padat.
- Scroll tetap natural.

---

## Tugas Opsional

### 10. Tambahkan Transisi Halus Antar Screen

Tugas:

Tambahkan transisi ringan jika memang terasa cocok.

Catatan:

Jangan semua elemen diberi animasi. Prioritaskan:

- splash ke auth/home
- card utama home
- empty state
- loading state

Kriteria selesai:

- Animasi terasa membantu.
- Tidak membuat app terasa lambat.
- Tidak mengganggu test widget.

---

### 11. Buat UI State Guide Singkat

Tugas:

Buat catatan internal singkat tentang standar UI app.

Isi minimal:

- warna utama
- style tombol utama
- style card
- style empty state
- style error state
- aturan animasi

File yang bisa dibuat:

```text
docs/ui-state-guide.md
```

Catatan:

Kerjakan ini setelah UI screen utama mulai konsisten. Jangan dibuat terlalu awal kalau style masih berubah-ubah.

---

## Checklist yang Harus Dilaporkan Anggil

Anggil perlu melaporkan:

- [ ] Screenshot splash screen.
- [ ] Screenshot login screen setelah polish.
- [ ] Screenshot home screen setelah polish.
- [ ] Screenshot active rental jika ikut dipoles.
- [ ] Screenshot rental history jika ikut dipoles.
- [ ] Bukti tidak ada overflow di layar kecil.
- [ ] Hasil `flutter analyze`.
- [ ] Catatan screen mana saja yang sudah dipoles.
- [ ] Catatan screen mana saja yang belum sempat dipoles.

---

## Perintah Verifikasi

Jalankan dari folder `mobile_user`:

```bash
flutter pub get
flutter analyze
flutter test
```

Jika menjalankan web:

```bash
flutter run -d chrome
```

---

## Catatan Teknis

Jangan mengubah default API base URL di repo.

Default yang harus tetap dipakai:

```dart
defaultValue: 'http://127.0.0.1:8000/api'
```

Jika butuh testing di HP fisik, jalankan dengan:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

Jangan commit file generated lokal seperti:

```text
mobile_bike/windows/flutter/ephemeral/
build/
.dart_tool/
```

Jika mengubah `home_screen.dart`, pastikan fitur dari branch lain tetap ada:

- Active Rental
- Live Map
- Idle Warning
- Rental History
