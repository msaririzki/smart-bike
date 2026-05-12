import 'package:flutter/material.dart';

import 'mock_route_service.dart';

class ManualGpsPanel extends StatefulWidget {
  const ManualGpsPanel({
    required this.onCoordinateSend,
    required this.onToggleSimulation,
    required this.isSimulating,
    required this.simulationProgress,
    required this.onIntervalChanged,
    required this.onModeChanged,
    required this.currentInterval,
    required this.currentMode,
    super.key,
  });

  final Function(double lat, double lng) onCoordinateSend;
  final VoidCallback onToggleSimulation;
  final bool isSimulating;
  final String simulationProgress;
  final Function(int seconds) onIntervalChanged;
  final Function(SimulationMode mode) onModeChanged;
  final int currentInterval;
  final SimulationMode currentMode;

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
        const SnackBar(content: Text('Koordinat manual dikirim.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Masukkan koordinat yang valid.')),
    );
  }

  void _selectPreset(LatLng? pos) {
    if (pos == null) return;
    setState(() {
      _latController.text = pos.latitude.toString();
      _lngController.text = pos.longitude.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_outlined, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Panel Kontrol Manual & Mock Route',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan bagian ini hanya saat demo atau debug koordinat.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 16),
          _label('Pilihan Preset Lokasi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _dropdownDeco(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LatLng>(
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                hint: const Text(
                  'Pilih Titik Lokasi',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: MockRouteService.locationPresets.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: _selectPreset,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Koordinat Manual'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDeco('Lintang (Lat)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDeco('Bujur (Lng)'),
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF334155), height: 1),
          ),
          _label('Konfigurasi Simulasi Rute'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jeda',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: _dropdownDeco(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: widget.currentInterval,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items: [3, 5, 10].map((seconds) {
                            return DropdownMenuItem(
                              value: seconds,
                              child: Text('$seconds detik'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) widget.onIntervalChanged(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: _dropdownDeco(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SimulationMode>(
                          value: widget.currentMode,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items: SimulationMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(_modeLabel(mode)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) widget.onModeChanged(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulasi Pergerakan Otomatis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isSimulating
                          ? widget.simulationProgress
                          : 'Status: berhenti',
                      style: TextStyle(
                        color: widget.isSimulating
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isSimulating,
                onChanged: (_) => widget.onToggleSimulation(),
                activeColor: const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

  BoxDecoration _dropdownDeco() => BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      );
}

String _modeLabel(SimulationMode mode) {
  return switch (mode) {
    SimulationMode.loop => 'Berulang',
    SimulationMode.stopAtEnd => 'Berhenti',
    SimulationMode.reset => 'Reset',
  };
}
