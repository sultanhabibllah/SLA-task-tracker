
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/sign_in_screen.dart';

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
      home: const SignInScreen(),
    );
  }
}
