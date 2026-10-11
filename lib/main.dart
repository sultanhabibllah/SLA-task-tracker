
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/shell/app_shell.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved application data before launching.
  final appState = AppState(StorageService());
  await appState.load();

  runApp(SprintlyApp(appState: appState));
}

class SprintlyApp extends StatelessWidget {
  const SprintlyApp({
    super.key,
    required this.appState,
  });

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Sprintly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

// Display Sign In until a team member is selected.
// Once signed in, display the main application shell.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AppState, bool>(
      (state) => state.currentUser != null,
    );

    return signedIn
        ? const AppShell()
        : const SignInScreen();
  }
}
