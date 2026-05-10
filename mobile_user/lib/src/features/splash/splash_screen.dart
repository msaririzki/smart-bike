import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A), // Dark premium
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Sepeda
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff1E293B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0f766e).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.pedal_bike_rounded,
                size: 72,
                color: Color(0xff14b8a6),
              ),
            ).animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            
            // Text Smart Bike Rental
            const Text(
              'Smart Bike Rental',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ).animate().fade(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 12),
            
            const Text(
              'Premium Smart Mobility',
              style: TextStyle(
                color: Color(0xff94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fade(delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 64),
            
            // Loading indicator modern
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff14b8a6)),
              ),
            ).animate().fade(delay: 1000.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
