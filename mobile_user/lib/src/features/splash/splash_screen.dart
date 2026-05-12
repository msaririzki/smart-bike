import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/flowbike3.svg',
                  height: 56,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(
                            text: 'Flow',
                            style: TextStyle(color: Color(0xFF349665)),
                          ),
                          TextSpan(
                            text: 'Bike',
                            style: TextStyle(color: Color(0xFF133C36)),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Ride Smooth. Track Smart.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),

            const SizedBox(height: 64),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF349665)),
              ),
            ).animate().fade(delay: 1000.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
