import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'screens.dart';
import 'auth_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makerere Hostel Finder',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Green theme for hostel/nature feel
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFFF6B35), // Orange accent
          tertiary: const Color(0xFF1976D2), // Blue for maps/location
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E7D32),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
          scrolledUnderElevation: 4,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
          selectedColor: const Color(0xFF2E7D32),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E7D32), // Dark green text
          ),
          secondaryLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white, // White text for selected chips
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginScreen();
        }
        return const MainScreen();
      },
    );
  }
}


