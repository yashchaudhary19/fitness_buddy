import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/router/router.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';

// --- DATA MODEL ---

class UserGoal {
  final String goalType;
  final double currentWeightKg;
  final double targetWeightKg;
  final double heightCm;
  final int age;
  final String gender;
  final String activityLevel;
  final double weeklyPaceKg;
  final int dailyCalorieTarget;
  final int dailyProteinG;
  final int dailyCarbsG;
  final int dailyFatG;
  final int dailyFiberG;
  final int dailyWaterMl;

  UserGoal({
    required this.goalType,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.weeklyPaceKg,
    required this.dailyCalorieTarget,
    required this.dailyProteinG,
    required this.dailyCarbsG,
    required this.dailyFatG,
    required this.dailyFiberG,
    required this.dailyWaterMl,
  });

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    // Helper to map possible legacy strings or varied capitalization to standard backend keys
    String mapGoalType(String? val) {
      final v = val?.toLowerCase() ?? 'maintain';
      if (v.contains('lose')) return 'lose';
      if (v.contains('gain')) return 'gain';
      if (v.contains('maintain')) return 'maintain';
      return 'maintain';
    }

    String mapActivityLevel(String? val) {
      final v = val?.toLowerCase() ?? 'sedentary';
      if (v.contains('very_active') || v.contains('extra')) return 'very_active';
      if (v.contains('active') && !v.contains('very_active')) return 'active';
      if (v.contains('moderate')) return 'moderate';
      if (v.contains('light')) return 'light';
      return 'sedentary';
    }

    String mapGender(String? val) {
      final v = val?.toLowerCase() ?? 'male';
      if (v.contains('male') && !v.contains('female')) return 'male';
      if (v.contains('female')) return 'female';
      return 'other';
    }

    return UserGoal(
      goalType: mapGoalType(json['goal_type']?.toString()),
      currentWeightKg: (json['current_weight_kg'] as num? ?? 70.0).toDouble(),
      targetWeightKg: (json['target_weight_kg'] as num? ?? 70.0).toDouble(),
      heightCm: (json['height_cm'] as num? ?? 170.0).toDouble(),
      age: (json['age'] as num? ?? 25).toInt(),
      gender: mapGender(json['gender']?.toString()),
      activityLevel: mapActivityLevel(json['activity_level']?.toString()),
      weeklyPaceKg: (json['weekly_pace_kg'] as num? ?? 0.5).toDouble(),
      dailyCalorieTarget: (json['daily_calorie_target'] as num? ?? 2000).toInt(),
      dailyProteinG: (json['daily_protein_g'] as num? ?? 150).toInt(),
      dailyCarbsG: (json['daily_carbs_g'] as num? ?? 150).toInt(),
      dailyFatG: (json['daily_fat_g'] as num? ?? 65).toInt(),
      dailyFiberG: (json['daily_fiber_g'] as num? ?? 25).toInt(),
      dailyWaterMl: (json['daily_water_ml'] as num? ?? 2000).toInt(),
    );
  }
}

// --- STATE MANAGEMENT ---

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final UserGoal? goal;

  ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.goal,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserGoal? goal,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      goal: goal ?? this.goal,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiService _apiService;
  final Ref _ref;

  ProfileNotifier(this._apiService, this._ref) : super(ProfileState());

  Future<void> fetchGoalProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.get(ApiConstants.goals);
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          goal: UserGoal.fromJson(response.data as Map<String, dynamic>),
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.error ?? "Failed to fetch goal profile.");
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("ApiException: ", ""),
      );
    }
  }

  Future<bool> updateGoalProfile({
    required String goalType,
    required double currentWeight,
    required double targetWeight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required double weeklyPace,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
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

      if (response.success && response.data != null) {
        final updatedGoal = UserGoal.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(isLoading: false, goal: updatedGoal);
        
        // Refresh dashboard summary parameters!
        _ref.read(summaryProvider.notifier).fetchSummary();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.error ?? "Failed to update goals.");
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("ApiException: ", ""),
      );
    }
    return false;
  }

  Future<void> logout() async {
    state = ProfileState(); // Clear local state immediately
    await _ref.read(authProvider.notifier).logout();
  }
}

// Profile provider declaration
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  
  // Listen for auth state changes to clear data on logout
  ref.listen(authStateProvider, (previous, next) {
    if (next == AuthState.unauthenticated) {
      ref.invalidateSelf();
    }
  });

  final notifier = ProfileNotifier(apiService, ref);
  
  // Only fetch if authenticated
  final authState = ref.watch(authStateProvider);
  if (authState == AuthState.authenticated) {
    notifier.fetchGoalProfile();
  }
  
  return notifier;
});
