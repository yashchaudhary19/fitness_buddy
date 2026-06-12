import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/network/token_storage.dart';
import 'package:frontend/core/router/router.dart';

class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;
  User? currentUser;

  AuthNotifier(this._apiService, this._ref) : super(AuthState.initial) {
    checkAuth();
    
    // Listen to Supabase auth state changes (e.g. after Google OAuth redirect)
    sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      debugPrint('Supabase Auth Change Event: $event, session present: ${session != null}');
      
      if (session != null && (event == sb.AuthChangeEvent.signedIn || event == sb.AuthChangeEvent.tokenRefreshed)) {
        final token = session.accessToken;
        debugPrint('Supabase Session detected! Exchanging with backend...');
        try {
          await _exchangeSupabaseToken(token);
        } catch (e, stackTrace) {
          debugPrint('Error exchanging Supabase token with backend: $e');
          debugPrint('Stacktrace: $stackTrace');
        }
      }
    });
  }

  Future<void> checkAuth() async {
    final token = TokenStorage.accessToken;
    if (token == null) {
      state = AuthState.unauthenticated;
      return;
    }

    try {
      // Validate token by fetching the profile
      final userResponse = await _apiService.get(ApiConstants.me);
      if (userResponse.success && userResponse.data != null) {
        final rawUser = userResponse.data;
        if (rawUser is! Map) {
          throw ApiException('Expected profile data to be a Map');
        }
        currentUser = User.fromJson(Map<String, dynamic>.from(rawUser));
        final onboardingCompleted = !TokenStorage.needsOnboarding;
        
        // Check if the user already has a goal set up on the backend
        try {
          final goalResponse = await _apiService.get(ApiConstants.goals);
          if (goalResponse.success && goalResponse.data != null) {
            await TokenStorage.setNeedsOnboarding(false);
            _ref.read(authStateProvider.notifier).state = AuthState.authenticated;
            state = AuthState.authenticated;
          } else {
            await TokenStorage.setNeedsOnboarding(true);
            _ref.read(authStateProvider.notifier).state = AuthState.needsOnboarding;
            state = AuthState.needsOnboarding;
          }
        } on ApiException catch (e) {
          // If goal endpoint returns 404, we need onboarding
          if (e.statusCode == 404) {
            await TokenStorage.setNeedsOnboarding(true);
            _ref.read(authStateProvider.notifier).state = AuthState.needsOnboarding;
            state = AuthState.needsOnboarding;
          } else {
            // General failure, fall back to authenticated if token is valid and onboarding completed
            if (onboardingCompleted) {
              _ref.read(authStateProvider.notifier).state = AuthState.authenticated;
              state = AuthState.authenticated;
            } else {
              _ref.read(authStateProvider.notifier).state = AuthState.needsOnboarding;
              state = AuthState.needsOnboarding;
            }
          }
        }
      } else {
        await logout();
      }
    } catch (_) {
      // If offline or request fails, assume authenticated if we have a token and onboarding is completed
      final onboardingCompleted = !TokenStorage.needsOnboarding;
      if (onboardingCompleted) {
        _ref.read(authStateProvider.notifier).state = AuthState.authenticated;
        state = AuthState.authenticated;
      } else {
        _ref.read(authStateProvider.notifier).state = AuthState.needsOnboarding;
        state = AuthState.needsOnboarding;
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.success && response.data != null) {
        final rawData = response.data;
        if (rawData is! Map) {
          throw ApiException('Expected response data to be a Map');
        }
        final resData = Map<String, dynamic>.from(rawData);
        final rawUser = resData['user'];
        if (rawUser is! Map) {
          throw ApiException('Expected user field to be a Map');
        }
        final userMap = Map<String, dynamic>.from(rawUser);
        currentUser = User.fromJson(userMap);

        await TokenStorage.saveTokens(
          accessToken: resData['access_token']?.toString() ?? '',
          refreshToken: resData['refresh_token']?.toString() ?? '',
        );

        // Check if they have a goal
        await checkAuth();
      } else {
        throw ApiException(response.error ?? "Failed to log in.");
      }
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      if (response.success && response.data != null) {
        final rawData = response.data;
        if (rawData is! Map) {
          throw ApiException('Expected response data to be a Map');
        }
        final resData = Map<String, dynamic>.from(rawData);
        final rawUser = resData['user'];
        if (rawUser is! Map) {
          throw ApiException('Expected user field to be a Map');
        }
        final userMap = Map<String, dynamic>.from(rawUser);
        currentUser = User.fromJson(userMap);

        await TokenStorage.saveTokens(
          accessToken: resData['access_token']?.toString() ?? '',
          refreshToken: resData['refresh_token']?.toString() ?? '',
        );

        await TokenStorage.setNeedsOnboarding(true);
        _ref.read(authStateProvider.notifier).state = AuthState.needsOnboarding;
        state = AuthState.needsOnboarding;
      } else {
        throw ApiException(response.error ?? "Failed to register.");
      }
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In: starting process');
      final supabase = sb.Supabase.instance.client;

      // Launch Google OAuth via Supabase (opens browser)
      debugPrint('Google Sign-In: launching OAuth provider');
      await supabase.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: 'io.supabase.nutritrack://login-callback',
      );
      debugPrint('Google Sign-In: OAuth provider launched successfully');
    } catch (e) {
      debugPrint('Google Sign-In: Error launching OAuth: $e');
      rethrow;
    }
  }

  Future<void> _exchangeSupabaseToken(String supabaseToken) async {
    // If the state is already authenticated or needs onboarding and we have currentUser, skip
    if ((state == AuthState.authenticated || state == AuthState.needsOnboarding) && currentUser != null) {
      debugPrint('Google Sign-In: Already authenticated/onboarding, skipping backend token exchange');
      return;
    }

    // Set state to loading so that it redirects to the SplashPage (shows spinner)
    _ref.read(authStateProvider.notifier).state = AuthState.loading;
    state = AuthState.loading;
    
    debugPrint('Google Sign-In: exchanging token with backend...');
    try {
      final response = await _apiService.post(
        ApiConstants.googleAuth,
        data: {'supabase_token': supabaseToken},
      );

      if (response.success && response.data != null) {
        debugPrint('Google Sign-In: backend exchange success!');
        final rawData = response.data;
        if (rawData is! Map) {
          throw ApiException('Expected response data to be a Map, but got ${rawData.runtimeType}');
        }
        final resData = Map<String, dynamic>.from(rawData);
        final rawUser = resData['user'];
        if (rawUser is! Map) {
          throw ApiException('Expected user field to be a Map, but got ${rawUser.runtimeType}');
        }
        final userMap = Map<String, dynamic>.from(rawUser);
        currentUser = User.fromJson(userMap);

        await TokenStorage.saveTokens(
          accessToken: resData['access_token']?.toString() ?? '',
          refreshToken: resData['refresh_token']?.toString() ?? '',
        );

        // Verify and set local auth state
        await checkAuth();
      } else {
        _ref.read(authStateProvider.notifier).state = AuthState.unauthenticated;
        state = AuthState.unauthenticated;
        debugPrint('Google Sign-In: backend exchange failed: ${response.error}');
        throw ApiException(response.error ?? 'Google sign-in token exchange failed.');
      }
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In: ERROR in exchange: $e');
      debugPrint('Google Sign-In: StackTrace: $stackTrace');
      _ref.read(authStateProvider.notifier).state = AuthState.unauthenticated;
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> submitOnboarding({
    required String goalType,
    required double currentWeight,
    required double targetWeight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required double weeklyPace,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.goals,
        data: {
          'goal_type': goalType,
          'current_weight_kg': currentWeight,
          'target_weight_kg': targetWeight,
          'height_cm': height,
          'age': age,
          'gender': gender,
          'activity_level': activityLevel,
          'weekly_pace_kg': weeklyPace,
        },
      );

      if (response.success) {
        await TokenStorage.setNeedsOnboarding(false);
        _ref.read(authStateProvider.notifier).state = AuthState.authenticated;
        state = AuthState.authenticated;
      } else {
        throw ApiException(response.error ?? "Failed to submit onboarding goals.");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    await TokenStorage.clear();
    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _ref.read(authStateProvider.notifier).state = AuthState.unauthenticated;
    state = AuthState.unauthenticated;
  }
}

// Riverpod Provider declaration
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService, ref);
});
