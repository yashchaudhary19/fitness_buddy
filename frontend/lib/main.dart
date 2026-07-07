import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/settings_storage.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/core/router/router.dart';
import 'package:frontend/core/network/token_storage.dart';
import 'package:frontend/core/ads/ad_service.dart';

void main() async {
  // Ensure Flutter engine bindings are fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Hive database & Token Storage (resiliently)
    try {
      await Hive.initFlutter();
      await TokenStorage.init();
      await SettingsStorage.init();
    } catch (e) {
      debugPrint('Hive/TokenStorage/SettingsStorage initialization failed, attempting recovery: $e');
      try {
        // Recovery: try deleting the Hive box files and re-initializing
        await Hive.deleteBoxFromDisk(TokenStorage.boxName);
        await Hive.deleteBoxFromDisk(SettingsStorage.boxName);
        await Hive.initFlutter();
        await TokenStorage.init();
        await SettingsStorage.init();
      } catch (recoveryError) {
        debugPrint('Hive recovery failed: $recoveryError');
        rethrow;
      }
    }

    // 2. Initialize AdMob SDK (non-blocking)
    try {
      await AdService.initialize();
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }

    // 3. Initialize Supabase (non-blocking to prevent offline DNS failures from crashing startup)
    try {
      await Supabase.initialize(
        url: 'https://pxcwkgrpkkoukgaqicky.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4Y3drZ3Jwa2tvdWtnYXFpY2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MDMxNTMsImV4cCI6MjA5NTI3OTE1M30.jcQliptd6QNZ6B08KtwYmZl4EBwgysMRLZQb7A93J-0',
      );
    } catch (e) {
      debugPrint('Supabase initialization failed (app will run in offline mode): $e');
    }

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Startup Error:\n$e',
                        style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stacktrace:\n$stackTrace',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'NutriTrack',
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router settings
      routerConfig: router,
    );
  }
}
