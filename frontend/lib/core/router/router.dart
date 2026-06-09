import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/network/token_storage.dart';
import 'package:frontend/features/auth/presentation/splash_page.dart';
import 'package:frontend/features/auth/presentation/login_page.dart';
import 'package:frontend/features/auth/presentation/register_page.dart';
import 'package:frontend/features/auth/presentation/welcome_page.dart';
import 'package:frontend/features/auth/presentation/onboarding_page.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_frame.dart';
import 'package:frontend/features/diary/presentation/log_food_page.dart';
import 'package:frontend/features/diary/presentation/scan_meal_page.dart';
import 'package:frontend/features/diary/presentation/scan_barcode_page.dart';
import 'package:frontend/features/diary/presentation/water_logging_page.dart';
import 'package:frontend/features/diary/presentation/add_exercise_page.dart';
import 'package:frontend/features/dashboard/presentation/premium_page.dart';

// Auth state provider synchronized with TokenStorage on startup
final authStateProvider = StateProvider<AuthState>((ref) {
  final token = TokenStorage.accessToken;
  if (token == null) {
    return AuthState.unauthenticated;
  }
  if (TokenStorage.needsOnboarding) {
    return AuthState.needsOnboarding;
  }
  return AuthState.authenticated;
});

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsOnboarding,
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthRoute = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      
      // If we are still checking auth status (initial or loading), stay on splash
      if (authState == AuthState.initial || authState == AuthState.loading) {
        return '/';
      }

      // If unauthenticated and not on an auth route, go to welcome
      if (authState == AuthState.unauthenticated) {
        return isAuthRoute ? null : '/welcome';
      }

      // If needs onboarding and not already going there, go to onboarding
      if (authState == AuthState.needsOnboarding) {
        return state.matchedLocation == '/onboarding' ? null : '/onboarding';
      }

      // If authenticated and on splash/auth routes/onboarding, go to dashboard
      if (authState == AuthState.authenticated) {
        if (state.matchedLocation == '/' || isAuthRoute || state.matchedLocation == '/onboarding') {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardFrame(),
      ),
      GoRoute(
        path: '/log-food',
        builder: (context, state) => const LogFoodPage(),
      ),
      GoRoute(
        path: '/scan-meal',
        builder: (context, state) => const ScanMealPage(),
      ),
      GoRoute(
        path: '/scan-barcode',
        builder: (context, state) => const ScanBarcodePage(),
      ),
      GoRoute(
        path: '/log-water',
        builder: (context, state) => const WaterLoggingPage(),
      ),
      GoRoute(
        path: '/add-exercise',
        builder: (context, state) => const AddExercisePage(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumPage(),
      ),
    ],
  );
});
