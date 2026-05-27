import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/router/router.dart';
import 'package:frontend/core/network/token_storage.dart';
import 'package:frontend/core/ads/ad_service.dart';

void main() async {
  // Ensure Flutter engine bindings are fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob SDK
  await AdService.initialize();

  // Initialize Hive database
  await Hive.initFlutter();
  
  // Initialize Hive token box
  await TokenStorage.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pxcwkgrpkkoukgaqicky.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4Y3drZ3Jwa2tvdWtnYXFpY2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MDMxNTMsImV4cCI6MjA5NTI3OTE1M30.jcQliptd6QNZ6B08KtwYmZl4EBwgysMRLZQb7A93J-0',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NutriTrack',
      debugShowCheckedModeBanner: false,
      
      // Theme settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to deep black obsidian theme

      // Router settings
      routerConfig: router,
    );
  }
}
