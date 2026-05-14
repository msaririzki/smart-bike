import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import 'active_rental_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  final _manualController = TextEditingController();
  bool _isProcessing = false;
  bool _showManualInput = kIsWeb;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  String? _parseToken(String rawValue) {
    // Format 1: smartbike://rent?token=qr_xxxxxxxxx
    final uri = Uri.tryParse(rawValue);
    if (uri != null && uri.scheme == 'smartbike' && uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token'];
    }

    // Format 2: bare token qr_xxxxxxxxx
    if (rawValue.startsWith('qr_') && rawValue.length > 5) {
      return rawValue;
    }

    return null;
  }

  Future<void> _processToken(String token) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      _controller?.stop();
      await widget.api.startRentalFromQr(token);
      if (!mounted) return;

      // Navigate to active rental
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ActiveRentalScreen(api: widget.api)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isProcessing = false;
      });
      _controller?.start();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal menghubungi server. Periksa koneksi internet.';
        _isProcessing = false;
      });
      _controller?.start();
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      final token = _parseToken(rawValue);
      if (token != null) {
        _processToken(token);
        return;
      }
    }
  }

  void _submitManualToken() {
    final input = _manualController.text.trim();
    if (input.isEmpty) return;

    final token = _parseToken(input) ?? input;
    _processToken(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR Sepeda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(
                _showManualInput ? Icons.camera_alt_rounded : Icons.keyboard_rounded,
              ),
              tooltip: _showManualInput ? 'Buka Kamera' : 'Input Manual',
              onPressed: () {
                setState(() => _showManualInput = !_showManualInput);
                if (!_showManualInput) {
                  _controller?.start();
                } else {
                  _controller?.stop();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showManualInput
                ? _buildManualInput()
                : _buildCameraScanner(),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraScanner() {
    final controller = _controller;
    if (controller == null) return _buildManualInput();

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onBarcodeDetected,
        ),
        // Scanner overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryLight, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Instruction text
        const Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Text(
            'Arahkan kamera ke QR di sepeda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 72,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 20),
            const Text(
              'Input Token QR Manual',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Kamera tidak tersedia di browser.\nMasukkan token QR secara manual.'
                  : 'Masukkan token QR dari sepeda.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _manualController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'smartbike://rent?token=qr_xxx atau qr_xxx',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submitManualToken(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _submitManualToken,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isProcessing ? 'Memproses...' : 'Mulai Sewa'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_error == null && !_isProcessing) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _isProcessing ? const Color(0xFF1E293B) : const Color(0x33EF4444),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryLight,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Memulai rental...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() => _error = null);
                  if (!_showManualInput) _controller?.start();
                },
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
