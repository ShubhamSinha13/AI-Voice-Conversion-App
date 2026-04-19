import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screens.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VoiceConverterApp()));
}

class VoiceConverterApp extends StatelessWidget {
  const VoiceConverterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Auth Gate - Routes to Login/Register or Home based on auth state
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isOnLoginScreen = true;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If authenticated, show home screen
    if (isAuthenticated) {
      return const HomeScreen();
    }

    // Otherwise show auth screens with toggle
    return _isOnLoginScreen
        ? LoginScreen(
            onRegisterTap: () {
              setState(() => _isOnLoginScreen = false);
            },
          )
        : RegisterScreen(
            onLoginTap: () {
              setState(() => _isOnLoginScreen = true);
            },
          );
  }
}
