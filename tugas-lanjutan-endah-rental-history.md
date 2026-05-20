# Tugas Lanjutan Endah - Rental History

Tanggal: 11 Mei 2026  
Anggota: Endah Komariah Lestari  
Branch sebelumnya: `feature/rental-history`  
Status: update terbaru sudah masuk ke `main`

---

## Kondisi Saat Ini

Update terbaru fitur Rental History sudah digabung ke `main`.

Yang sudah tersedia:

- Screen daftar riwayat rental.
- Screen detail rental.
- Model `RentalHistory`.
- API `rentalHistory(page: ...)`.
- Filter status:
  - Semua
  - Selesai
  - Dibatalkan
- Filter periode:
  - Semua Waktu
  - 7 Hari Terakhir
  - Bulan Ini
- Pagination / load more.
- Loading skeleton.
- Empty state.
- Error state dengan pull-to-refresh.
- Detail rental dengan ringkasan:
  - jarak
  - durasi
  - average speed
  - estimasi kalori
  - biaya jarak
  - biaya idle
  - total biaya
  - estimasi dampak lingkungan
- Bottom sheet highlight perjalanan.
- Tombol salin ringkasan perjalanan.

---

## Tugas Lanjutan Prioritas Tinggi

### 1. Test History Dengan Data Backend Real

Tujuan:

memastikan data history yang tampil benar-benar sesuai response backend.

Langkah:

1. Pull `main` terbaru.
2. Jalankan backend.
3. Login sebagai user.
4. Buat minimal 3 rental:
   - 1 rental selesai normal
   - 1 rental dengan jarak lebih panjang
   - 1 rental yang punya idle cost jika memungkinkan
5. Buka menu `Riwayat`.
6. Buka detail tiap rental.

Kriteria selesai:

- Semua rental completed muncul di history.
- Bike code sesuai.
- Tanggal mulai sesuai.
- Tanggal selesai sesuai.
- Total distance sesuai backend.
- Distance cost sesuai backend.
- Idle cost sesuai backend.
- Total cost sesuai backend.

Catatan:

Jika ada angka yang berbeda, catat response API dari:

```text
GET /api/rentals/history
```

---

### 2. Test Pagination / Load More

Tujuan:

memastikan list history tetap berjalan jika data lebih dari satu halaman.

Langkah:

1. Buat data history lebih dari jumlah item per page backend.
2. Buka menu `Riwayat`.
3. Scroll sampai bawah.

Kriteria selesai:

- Data halaman pertama tampil.
- Saat scroll bawah, data halaman berikutnya dimuat.
- Loading bawah muncul.
- Data tidak duplikat.
- Jika sudah halaman terakhir, loading bawah berhenti.

Catatan:

Kalau data testing masih sedikit, minta bantuan untuk seed beberapa rental completed di backend.

---

### 3. Test Filter Status

Tujuan:

memastikan filter status bekerja sesuai data.

Filter yang harus dites:

- Semua
- Selesai
- Dibatalkan

Kriteria selesai:

- `Semua` menampilkan semua history.
- `Selesai` hanya menampilkan status `completed`.
- `Dibatalkan` hanya menampilkan status `cancelled`.
- Jika tidak ada data yang cocok, empty state filter muncul.

Catatan:

Jika backend belum punya rental `cancelled`, minimal pastikan empty state filter `Dibatalkan` tampil aman.

---

### 4. Test Filter Periode

Tujuan:

memastikan filter waktu berjalan benar.

Filter yang harus dites:

- Semua Waktu
- 7 Hari Terakhir
- Bulan Ini

Kriteria selesai:

- `Semua Waktu` menampilkan seluruh data.
- `7 Hari Terakhir` hanya menampilkan rental dalam 7 hari terakhir.
- `Bulan Ini` hanya menampilkan rental bulan berjalan.
- Empty state muncul jika tidak ada data sesuai periode.

Catatan:

Gunakan data seed atau ubah tanggal rental di database testing jika perlu.

---

### 5. Test Empty State dan Error State

Tujuan:

memastikan UX aman saat data kosong atau API gagal.

Empty state:

1. Login dengan user baru.
2. Buka `Riwayat`.

Kriteria selesai:

- Muncul pesan belum ada riwayat.
- Pull-to-refresh tetap bisa dilakukan.
- App tidak crash.

Error state:

1. Matikan backend.
2. Buka `Riwayat`.

Kriteria selesai:

- Error state muncul.
- Tombol retry / pull-to-refresh bisa dipakai.
- App tidak stuck loading.

---

## Tugas Lanjutan Prioritas Sedang

### 6. Validasi Tampilan di Layar Kecil

Tujuan:

memastikan UI tidak overflow di emulator kecil.

Cek layar:

- History list
- Filter chips
- Summary card
- Weekly chart
- Detail rental
- Bottom sheet highlight

Kriteria selesai:

- Tidak ada overflow kuning/hitam.
- Filter chips bisa scroll horizontal.
- Card history tetap terbaca.
- Detail biaya tidak bertabrakan.
- Bottom sheet bisa discroll.

---

### 7. Rapikan Label Estimasi

Beberapa nilai bukan data resmi dari backend, tetapi estimasi dari frontend.

Nilai estimasi:

- CO2 saved
- Kalori
- Average speed jika dihitung dari distance/duration

Tugas:

- Pastikan label memakai kata `Estimasi`.
- Jangan menampilkan seolah-olah itu data final dari backend.

Contoh label:

- `Estimasi CO2`
- `Est. Kalori`
- `Rata-rata Kecepatan`

---

### 8. Cek Ringkasan yang Disalin ke Clipboard

Tugas:

Pastikan tombol `Salin Ringkasan` menghasilkan teks yang rapi.

Cek isi:

- bike code
- jarak
- durasi
- kalori
- total biaya

Kriteria selesai:

- Teks bisa dicopy.
- Tidak ada karakter rusak.
- Format rupiah terbaca.
- Ringkasan tetap aman jika bike null.

---

### 9. Tambahkan State Saat Filter Aktif

Tugas:

Berikan indikator kecil bahwa filter sedang aktif.

Contoh:

- Text: `Menampilkan hasil filter`
- Tombol kecil: `Reset filter`

Kriteria selesai:

- User tahu kenapa list terlihat sedikit/kosong.
- User bisa kembali ke semua data dengan cepat.

---

## Tugas Opsional

### 10. Search History

Tambahkan pencarian berdasarkan:

- bike code
- bike name

Contoh:

User mengetik `BIKE-001`, list hanya menampilkan rental dari sepeda tersebut.

---

### 11. Detail Route History

Jika backend nanti menyediakan route points untuk rental completed, tambahkan mini map di detail history.

Butuh koordinasi dengan:

- Arya untuk `MapWidget`
- backend untuk endpoint route history

Kriteria selesai:

- Detail rental bisa menampilkan rute perjalanan yang sudah selesai.
- Jika route kosong, tampilkan fallback yang aman.

---

## Testing Gabungan Dengan Anggota Lain

### Dengan Jul Hadi

Tujuan:

memastikan data dari simulator bisa menjadi history.

Langkah:

1. Jul Hadi jalankan `mobile_bike`.
2. User mulai rental di `mobile_user`.
3. Jul Hadi aktifkan mock route.
4. User selesai rental.
5. Endah cek menu `Riwayat`.

Kriteria selesai:

- Rental baru muncul di history.
- Detail history sesuai data rental yang baru selesai.

### Dengan Riki

Tujuan:

memastikan transisi Active Rental ke History aman.

Langkah:

1. Mulai rental.
2. Buka Active Rental.
3. Selesaikan rental dari Active Rental.
4. Buka History.

Kriteria selesai:

- Setelah rental selesai, data muncul di History.
- Total biaya di Active Rental sama dengan Detail History.

---

## Checklist Laporan Endah

Endah perlu melaporkan:

- [ ] Screenshot list history dengan data real.
- [ ] Screenshot filter status.
- [ ] Screenshot filter periode.
- [ ] Screenshot empty state.
- [ ] Screenshot error state jika sempat dites.
- [ ] Screenshot detail rental.
- [ ] Bukti total biaya sama dengan backend.
- [ ] Bukti tombol salin ringkasan berfungsi.
- [ ] Catatan jika ada overflow di layar kecil.

---

## Catatan Teknis

Saat mengubah `api_client.dart`, jangan mengganti default `API_BASE_URL` ke IP lokal pribadi.

Gunakan default repo:

```dart
defaultValue: 'http://127.0.0.1:8000/api'
```

Jika butuh IP laptop untuk HP asli, jalankan app dengan:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api
```

Jangan commit file generated lokal seperti:

```text
mobile_bike/windows/flutter/ephemeral/
```

