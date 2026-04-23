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
    final baseLight = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    final baseDark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Voice Converter',
      theme: baseLight.copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: baseLight.colorScheme.surface,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: baseLight.colorScheme.outlineVariant,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: baseLight.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: baseLight.colorScheme.primary, width: 1.6),
          ),
        ),
      ),
      darkTheme: baseDark.copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: baseDark.colorScheme.surface,
        ),
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
