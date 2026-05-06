import 'package:flutter/material.dart';

import 'src/features/rental/map_test_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Smart Bike - Map Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
        ),
        useMaterial3: true,
      ),
      home: const MapTestScreen(),
    ),
  );
}
