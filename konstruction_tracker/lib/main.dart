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

// Professional Blue & Gray Theme Configuration (Preview)
ThemeData _buildLightTheme() {
  const Color primaryBlue = Color(0xFF1976D2); // Deep blue
  const Color secondaryGray = Color(0xFF546E7A); // Warm gray
  const Color lightBackground = Color(0xFFFAFAFA); // Light gray background
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE3F2FD), // Light blue container
      onPrimaryContainer: primaryBlue,
      secondary: secondaryGray,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF212121), // Dark gray text
      surfaceVariant: lightBackground,
      onSurfaceVariant: secondaryGray,
      outline: Color(0xFFBDBDBD), // Light gray outline
      error: Color(0xFFD32F2F), // Red for errors
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: primaryBlue,
      surfaceTintColor: primaryBlue,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      surfaceTintColor: Color(0xFFE3F2FD), // Light blue tint
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlue,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const Color primaryBlue = Color(0xFF1976D2); // Deep blue
  const Color secondaryGray = Color(0xFF546E7A); // Warm gray
  const Color darkBackground = Color(0xFF121212); // Material dark background
  const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter dark
  
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF0D47A1), // Darker blue container
      onPrimaryContainer: Color(0xFFBBDEFB), // Light blue text
      secondary: secondaryGray,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
      surfaceVariant: Color(0xFF2C2C2C),
      onSurfaceVariant: Colors.white70,
      outline: Color(0xFF757575), // Medium gray outline
      background: darkBackground,
      onBackground: Colors.white,
      error: Color(0xFFD32F2F), // Red for errors
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: darkBackground,
      foregroundColor: primaryBlue,
      surfaceTintColor: primaryBlue,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: darkSurface,
      surfaceTintColor: primaryBlue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlue,
    ),
  );
}

