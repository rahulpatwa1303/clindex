import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Pass at build time:
    //   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
    //               --dart-define=SUPABASE_ANON_KEY=eyJ...
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ClindexApp());
}

class ClindexApp extends StatelessWidget {
  const ClindexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clindex',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Listens to Supabase auth state and routes to LoginScreen or the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Use the persisted session immediately if available,
        // otherwise wait for the stream's first event.
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        if (session != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
