import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SmartBikeSimulator());
}

class SmartBikeSimulator extends StatelessWidget {
  const SmartBikeSimulator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bike Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF22C55E),
          surface: const Color(0xFF1E293B),
          error: Colors.red.shade400,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const App(),
    );
  }
}
