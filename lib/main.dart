import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const QrToolkitApp());

class QrToolkitApp extends StatelessWidget {
  const QrToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}