import 'package:flutter/material.dart';

import 'src/ui/workbench_screen.dart';

void main() {
  runApp(const FlutwareApp());
}

class FlutwareApp extends StatelessWidget {
  const FlutwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutware',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B7DE9)),
        scaffoldBackgroundColor: const Color(0xFFE9EEF5),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const WorkbenchScreen(),
    );
  }
}
