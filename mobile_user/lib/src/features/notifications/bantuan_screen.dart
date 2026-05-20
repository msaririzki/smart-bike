import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key, this.bikeId});

  final String? bikeId;

  Future<void> _launchWA(BuildContext context) async {
    final defaultId = bikeId ?? 'Tidak Diketahui';
    final text = 'Halo Admin SBR, saya mengalami kendala dengan Sewa Sepeda ID: $defaultId';
    final url = Uri.parse('https://api.whatsapp.com/send?phone=6285198465297&text=${Uri.encodeComponent(text)}');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  void _laporkanSepeda(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Layanan otomatis akan segera hadir! Untuk sementara, silakan laporkan kendala Anda secara langsung melalui tombol Hubungi Admin SBR di bawah.'),
        duration: Duration(seconds: 4),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xff374151)),
        ),
        iconColor: AppColors.primaryLight,
        collapsedIconColor: const Color(0xff9ca3af),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: const TextStyle(color: Color(0xff6b7280), height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Bantuan', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FAQ Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('❓ Pertanyaan Sering Diajukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff111827))),
                  ),
                  _buildFaqItem(
                    'Bagaimana jika sepeda tidak bisa dikunci kembali?',
                    'Pastikan Anda berada di area Shelter resmi (cek peta). Coba tekan kembali kunci fisik secara manual atau tekan tombol "Akhiri Sewa" dua kali di aplikasi untuk memaksa penyegaran status kunci.',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildFaqItem(
                    'Aplikasi eror saat perjalanan sedang berlangsung?',
                    'Jangan khawatir, server tetap mencatat waktu perjalanan Anda secara aman. Coba restart aplikasi Anda. Jika tarif tetap berjalan salah setelah aplikasi dibuka kembali, segera hubungi admin melalui menu di bawah.',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildFaqItem(
                    'Bagaimana jika baterai smartphone saya mati?',
                    'Sistem di sepeda tetap aktif. Anda bisa meminjam ponsel teman untuk login ke akun Anda atau langsung menuju shelter terdekat untuk meminta bantuan petugas lapangan kunci manual.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚨 Laporkan Kendala Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff111827))),
                  const SizedBox(height: 8),
                  const Text('Gunakan fitur ini jika Anda memerlukan bantuan darurat saat menyewa sepeda.', style: TextStyle(fontSize: 14, color: Color(0xff6b7280))),
                  const SizedBox(height: 16),
                  
                  // Tombol Laporkan Sepeda Rusak
                  ElevatedButton.icon(
                    onPressed: () => _laporkanSepeda(context),
                    icon: const Icon(Icons.build_rounded),
                    label: const Text('Laporkan Sepeda Rusak / Ban Bocor', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffef4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tombol Hubungi Admin WA
                  ElevatedButton.icon(
                    onPressed: () => _launchWA(context),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Hubungi Admin SBR (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
