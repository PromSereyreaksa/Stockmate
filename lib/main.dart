import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/main_navigation.dart';
import 'data/data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed initial data (only seeds if database is empty)
  print("🌱 Checking data...");
  try {
    await DataSeeder().seedInitialData();
    print("✅ Data ready!");
  } catch (e) {
    print("❌ Data seeding failed: $e");
  }
  
  // Locking this because running a mobile emulator lags alot 
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    const windowOptions = WindowOptions(
      size: Size(400, 800),
      minimumSize: Size(400, 800),
      maximumSize: Size(400, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'StockMate',
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}
