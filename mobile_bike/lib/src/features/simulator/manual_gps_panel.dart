import 'package:flutter/material.dart';

class ManualGpsPanel extends StatefulWidget {
  const ManualGpsPanel({
    required this.onCoordinateSend,
    required this.onToggleSimulation,
    required this.isSimulating,
    required this.simulationProgress,
    super.key,
  });

  final Function(double lat, double lng) onCoordinateSend;
  final VoidCallback onToggleSimulation;
  final bool isSimulating;
  final String simulationProgress;

  @override
  State<ManualGpsPanel> createState() => _ManualGpsPanelState();
}

class _ManualGpsPanelState extends State<ManualGpsPanel> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submitManual() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      widget.onCoordinateSend(lat, lng);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat manual dikirim!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan koordinat yang valid.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛠 Control Panel (Manual & Mock)',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Manual Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDeco('Latitude'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDeco('Longitude'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitManual,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Kirim Koordinat Ini'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF334155), height: 1),
          ),
          
          // Mock Route Simulation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulasi Rute Otomatis',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (widget.isSimulating)
                      Text(
                        widget.simulationProgress,
                        style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12),
                      )
                    else
                      const Text(
                        'Status: Berhenti',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                  ],
                ),
              ),
              Switch(
                value: widget.isSimulating,
                onChanged: (_) => widget.onToggleSimulation(),
                activeThumbColor: const Color(0xFF22C55E),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Interval: 5 detik per titik. Gunakan untuk test pergerakan tanpa GPS fisik.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
      );
}
