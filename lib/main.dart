import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';
import 'screens/home_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => HistoryProvider()..load(),
    child: const QrToolkitApp(),
  ),
);

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