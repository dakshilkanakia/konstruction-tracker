import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
// import 'services/storage_service.dart'; // TODO: Enable in Phase 3
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  
  runApp(const KonstructionApp());
}

class KonstructionApp extends StatelessWidget {
  const KonstructionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        // Provider(create: (_) => StorageService()), // TODO: Enable in Phase 3
      ],
      child: MaterialApp(
        title: 'Konstruction Tracker',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system, // Automatically switch based on system preference
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const AuthScreen();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Gold and Black Theme Configuration
ThemeData _buildLightTheme() {
  const Color goldColor = Color(0xFFFFD700); // Pure gold
  const Color darkGoldColor = Color(0xFFB8860B); // Dark goldenrod
  const Color lightGoldColor = Color(0xFFFFF8DC); // Cornsilk
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: goldColor,
      onPrimary: Colors.black,
      primaryContainer: lightGoldColor,
      onPrimaryContainer: Colors.black,
      secondary: darkGoldColor,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      surfaceVariant: Color(0xFFFAFAFA),
      onSurfaceVariant: Colors.black54,
      outline: darkGoldColor,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      surfaceTintColor: goldColor,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      surfaceTintColor: lightGoldColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: goldColor,
      foregroundColor: Colors.black,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: goldColor,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const Color goldColor = Color(0xFFFFD700); // Pure gold
  const Color darkGoldColor = Color(0xFFB8860B); // Dark goldenrod
  const Color darkBackground = Color(0xFF121212); // Material dark background
  const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter dark
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: goldColor,
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF2A2A2A),
      onPrimaryContainer: goldColor,
      secondary: darkGoldColor,
      onSecondary: Colors.black,
      surface: darkSurface,
      onSurface: Colors.white,
      surfaceVariant: Color(0xFF2C2C2C),
      onSurfaceVariant: Colors.white70,
      outline: goldColor,
      background: darkBackground,
      onBackground: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: darkBackground,
      foregroundColor: goldColor,
      surfaceTintColor: goldColor,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: darkSurface,
      surfaceTintColor: goldColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: goldColor,
      foregroundColor: Colors.black,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: goldColor,
    ),
  );
}

