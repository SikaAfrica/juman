import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/djuman_environment.dart';
import 'core/providers/router_provider.dart';
import 'core/offline/djuman_offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser l'environnement
  await DjumanEnvironment.initialize();

  // Initialiser le service offline SQLite avec sync avancé
  try {
    await DjumanOfflineService().init();
    print('✅ DjumanOfflineService initialisé (SQLite)');
  } catch (e) {
    print('⚠️ Erreur initialisation DjumanOfflineService: $e');
  }
  
  runApp(
    const ProviderScope(
      child: DjumanApp(),
    ),
  );
}

class DjumanApp extends ConsumerWidget {
  const DjumanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = DjumanTheme.lightTheme;

    return MaterialApp.router(
      title: 'DJUMAN - Trouvez le bon métier',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}

class DjumanTheme {
  static const primaryColor = Color(0xFFF2B41A); // Jaune (or)
  static const secondaryColor = Color(0xFF112B5C); // Bleu foncé (navy)
  static const accentColor = Color(0xFF00C853);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const errorColor = Color(0xFFDC2626);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2B41A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
