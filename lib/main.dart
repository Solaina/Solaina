import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/household_setup_screen.dart';
import 'screens/home_shell.dart';
import 'services/app_mode.dart';
import 'services/auth_service.dart';
import 'services/local_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppMode.useLocal = !DefaultFirebaseOptions.isConfigured;
  if (AppMode.useLocal) {
    await LocalStore.instance.init();
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const SolainaApp());
}

class SolainaApp extends StatelessWidget {
  const SolainaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solaina',
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<String?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final userId = authSnapshot.data;
        if (userId == null) {
          return const LoginScreen();
        }
        return StreamBuilder<AppUser?>(
          stream: authService.watchAppUser(userId),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            final appUser = userSnapshot.data;
            if (appUser == null) {
              return const _LoadingScreen();
            }
            if (appUser.householdId == null) {
              return HouseholdSetupScreen(appUser: appUser);
            }
            return HomeShell(
              appUser: appUser,
              householdId: appUser.householdId!,
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
