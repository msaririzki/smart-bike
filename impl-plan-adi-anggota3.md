# Implementation Plan — Anggota 3: Adi Saputra (Idle Warning UI)

**Branch:** `feature/idle-warning-ui`
**File utama:** `mobile_user/lib/src/features/rental/idle_warning_dialog.dart`

---

## Strategi: Kerja Mandiri Tanpa Menunggu Riki

Buat `IdleWarningDialog` sebagai widget mandiri dan tambahkan method API yang diperlukan.
Saat Riki selesai, integrasi hanya perlu menambahkan logika cek `status` di polling-nya.

---

## File yang Dikerjakan

### 1. MODIFY — `mobile_user/lib/src/services/api_client.dart`

Tambahkan 1 method baru di dalam class `ApiClient` (setelah method `finishRental`):

```dart
/// Kirim request agar rental tetap dilanjutkan meski idle
Future<void> continueIdle(int rentalId) async {
  await _post('/rentals/$rentalId/idle/continue', body: {});
}
```

> Method `finishRental(int rentalId)` sudah ada — tidak perlu dibuat ulang.

---

### 2. NEW — `mobile_user/lib/src/features/rental/idle_warning_dialog.dart`

Dialog peringatan saat sepeda idle:

```dart
import 'package:flutter/material.dart';

class IdleWarningDialog extends StatelessWidget {
  const IdleWarningDialog({
    super.key,
    required this.onContinue,
    required this.onFinish,
    this.isLoading = false,
  });

  /// Callback saat user pilih "Lanjutkan Sewa"
  final VoidCallback onContinue;

  /// Callback saat user pilih "Selesaikan Sewa"
  final VoidCallback onFinish;

  /// True saat sedang mengirim request ke server
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('Sepeda Diam!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sepeda tidak bergerak selama 5 menit.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Jika Anda memilih Lanjutkan, biaya idle akan dikenakan '
              'selama sepeda masih diam.',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            label: const Text('Selesaikan Sewa',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Lanjutkan Sewa'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff0f766e),
            ),
          ),
        ],
      ],
    );
  }
}
```

---

### 3. NEW — `mobile_user/lib/src/features/rental/idle_badge_widget.dart`

Badge status untuk ditampilkan di active_rental_screen saat status `idle_billing`:

```dart
import 'package:flutter/material.dart';

enum RentalStatus { active, idleWarning, idleBilling, other }

/// Konversi string status dari API ke enum
RentalStatus parseRentalStatus(String status) {
  switch (status) {
    case 'active':
      return RentalStatus.active;
    case 'idle_warning':
      return RentalStatus.idleWarning;
    case 'idle_billing':
      return RentalStatus.idleBilling;
    default:
      return RentalStatus.other;
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final parsed = parseRentalStatus(status);
    final (label, bgColor, textColor, icon) = switch (parsed) {
      RentalStatus.active => (
          'AKTIF',
          Colors.green.shade100,
          Colors.green.shade800,
          Icons.play_circle_outline,
        ),
      RentalStatus.idleWarning => (
          'IDLE WARNING',
          Colors.orange.shade100,
          Colors.orange.shade800,
          Icons.warning_amber_rounded,
        ),
      RentalStatus.idleBilling => (
          'IDLE BILLING',
          Colors.red.shade100,
          Colors.red.shade800,
          Icons.attach_money,
        ),
      RentalStatus.other => (
          status.toUpperCase(),
          Colors.grey.shade100,
          Colors.grey.shade800,
          Icons.info_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 4. NEW — `mobile_user/lib/src/features/rental/idle_test_screen.dart`

Screen sementara untuk test dialog secara mandiri (hapus setelah integrasi):

```dart
import 'package:flutter/material.dart';
import 'idle_warning_dialog.dart';
import 'idle_badge_widget.dart';

/// Screen ini HANYA untuk testing — hapus setelah integrasi dengan Riki
class IdleTestScreen extends StatefulWidget {
  const IdleTestScreen({super.key});
  @override
  State<IdleTestScreen> createState() => _IdleTestScreenState();
}

class _IdleTestScreenState extends State<IdleTestScreen> {
  String _status = 'active';
  bool _isLoading = false;

  void _simulateIdleWarning() {
    setState(() => _status = 'idle_warning');
    _showIdleDialog();
  }

  void _showIdleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IdleWarningDialog(
        isLoading: _isLoading,
        onContinue: () {
          setState(() => _isLoading = true);
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop();
            setState(() {
              _isLoading = false;
              _status = 'idle_billing';
            });
          });
        },
        onFinish: () {
          Navigator.of(context).pop();
          setState(() => _status = 'active');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sewa diselesaikan')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Idle Warning (Adi)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusBadge(status: _status),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _status = 'active'),
              child: const Text('Set Status: active'),
            ),
            ElevatedButton(
              onPressed: _simulateIdleWarning,
              child: const Text('Simulasi Idle Warning'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _status = 'idle_billing'),
              child: const Text('Set Status: idle_billing'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Cara Integrasi ke Screen Riki (Setelah Riki Selesai)

Di dalam `active_rental_screen.dart` Riki, Adi tinggal menambahkan:

1. Import:
```dart
import '../rental/idle_warning_dialog.dart';
import '../rental/idle_badge_widget.dart';
```

2. Tambah state flag:
```dart
bool _isIdleDialogShown = false;
```

3. Di dalam `Timer.periodic` polling, tambahkan cek status:
```dart
final newStatus = rental.status;
if (newStatus == 'idle_warning' && !_isIdleDialogShown) {
  _isIdleDialogShown = true;
  _showIdleDialog(rental.id);
}
if (newStatus == 'active' || newStatus == 'idle_billing') {
  _isIdleDialogShown = false;
  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
}
```

4. Tambah method `_showIdleDialog`:
```dart
void _showIdleDialog(int rentalId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => IdleWarningDialog(
      onContinue: () async {
        await widget.api.continueIdle(rentalId);
        if (mounted) Navigator.of(context).pop();
      },
      onFinish: () async {
        await widget.api.finishRental(rentalId);
        if (mounted) Navigator.of(context).pop();
        // navigasi balik ke home
      },
    ),
  );
}
```

5. Ganti tampilan status di body dengan `StatusBadge`:
```dart
StatusBadge(status: rental.status),
```

---

## Endpoint yang Dipakai

```
POST /api/rentals/{id}/idle/continue   ← user pilih lanjut
POST /api/rentals/{id}/finish          ← user pilih selesai (sudah ada)

GET  /api/rentals/active               ← polling status (dikerjakan Riki)
```

---

## Checklist

- [ ] Tambah method `continueIdle()` di `api_client.dart`
- [ ] Buat folder `mobile_user/lib/src/features/rental/`
- [ ] Buat `idle_warning_dialog.dart`
- [ ] Buat `idle_badge_widget.dart`
- [ ] Buat `idle_test_screen.dart` untuk test sementara
- [ ] Verifikasi dialog muncul dan tombol berfungsi
- [ ] Verifikasi badge status berubah warna sesuai status
- [ ] Koordinasi dengan Riki untuk integrasi
- [ ] Hapus `idle_test_screen.dart` setelah integrasi
- [ ] Push branch `feature/idle-warning-ui`
