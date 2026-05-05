import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const SoundMagicApp());
}

class SoundMagicApp extends StatelessWidget {
  const SoundMagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundMagic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF534AB7),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
      ),
      home: const MapScreen(),
    );
  }
}
