import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const SprintlyApp());
}

class SprintlyApp extends StatelessWidget {
  const SprintlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprintly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text(
            'Welcome to Sprintly',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}