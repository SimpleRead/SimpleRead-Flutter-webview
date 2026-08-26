import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SimpleReadShellApp());
}

/// Root widget of the SimpleRead hybrid native shell PoC.
class SimpleReadShellApp extends StatelessWidget {
  const SimpleReadShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleRead Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
