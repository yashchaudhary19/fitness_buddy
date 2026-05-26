import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/router/router.dart';

// --- DATA MODELS ---

class CaloriePoint {
  final DateTime date;
  final double caloriesConsumed;
  final double caloriesGoal;
  final double caloriesBurned;

  CaloriePoint({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.caloriesBurned,
  });

  factory CaloriePoint.fromJson(Map<String, dynamic> json) {
    return CaloriePoint(
      date: DateTime.parse(json['date']),
      caloriesConsumed: (json['calories_consumed'] as num? ?? 0.0).toDouble(),
      caloriesGoal: (json['calories_goal'] as num? ?? 0.0).toDouble(),
      caloriesBurned: (json['calories_burned'] as num? ?? 0.0).toDouble(),
    );
  }
}

class MacroPoint {
  final DateTime date;
  final double carbsG;
  final double proteinG;
  final double fatG;

  MacroPoint({
    required this.date,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  factory MacroPoint.fromJson(Map<String, dynamic> json) {
    return MacroPoint(
      date: DateTime.parse(json['date']),
      carbsG: (json['carbs_g'] as num? ?? 0.0).toDouble(),
      proteinG: (json['protein_g'] as num? ?? 0.0).toDouble(),
      fatG: (json['fat_g'] as num? ?? 0.0).toDouble(),
    );
  }
}

class WeightPoint {
  final DateTime date;
  final double weightKg;
  final double movingAverage7d;

  WeightPoint({
    required this.date,
    required this.weightKg,
    required this.movingAverage7d,
  });

  factory WeightPoint.fromJson(Map<String, dynamic> json) {
    return WeightPoint(
      date: DateTime.parse(json['date']),
      weightKg: (json['weight_kg'] as num? ?? 0.0).toDouble(),
      movingAverage7d: (json['moving_average_7d'] as num? ?? 0.0).toDouble(),
    );
  }
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: (json['current_streak'] as num? ?? 0).toInt(),
      longestStreak: (json['longest_streak'] as num? ?? 0).toInt(),
      lastActiveDate: json['last_active_date']?.toString(),
    );
  }
}

// --- STATE MANAGEMENT ---

class ProgressState {
  final bool isLoading;
  final String? errorMessage;
  final List<CaloriePoint> caloriesTimeline;
  final List<MacroPoint> macrosTimeline;
  final List<WeightPoint> weightTimeline;
  final StreakData? streak;
  final int selectedPeriodDays; // e.g. 7, 30 days

  ProgressState({
    this.isLoading = false,
    this.errorMessage,
    required this.caloriesTimeline,
    required this.macrosTimeline,
    required this.weightTimeline,
    this.streak,
    this.selectedPeriodDays = 7,
  });

  ProgressState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CaloriePoint>? caloriesTimeline,
    List<MacroPoint>? macrosTimeline,
    List<WeightPoint>? weightTimeline,
    StreakData? streak,
    int? selectedPeriodDays,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      caloriesTimeline: caloriesTimeline ?? this.caloriesTimeline,
      macrosTimeline: macrosTimeline ?? this.macrosTimeline,
      weightTimeline: weightTimeline ?? this.weightTimeline,
      streak: streak ?? this.streak,
      selectedPeriodDays: selectedPeriodDays ?? this.selectedPeriodDays,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ApiService _apiService;

  ProgressNotifier(this._apiService) : super(ProgressState(
    caloriesTimeline: [],
    macrosTimeline: [],
    weightTimeline: [],
  ));

  Future<void> fetchProgressData({int? periodDays}) async {
    final days = periodDays ?? state.selectedPeriodDays;
    state = state.copyWith(isLoading: true, errorMessage: null, selectedPeriodDays: days);

    try {
      // 1. Fetch Streak
      final streakResponse = await _apiService.get(ApiConstants.streak);
      StreakData? streak;
      if (streakResponse.success && streakResponse.data != null) {
        streak = StreakData.fromJson(streakResponse.data as Map<String, dynamic>);
      }

      // 2. Fetch Calories Timeline
      final calResponse = await _apiService.get(
        ApiConstants.caloriesTimeline,
        queryParameters: {'days': days},
      );
      List<CaloriePoint> calList = [];
      if (calResponse.success && calResponse.data is List) {
        final list = calResponse.data as List;
        calList = list.map((e) => CaloriePoint.fromJson(e as Map<String, dynamic>)).toList();
      }

      // 3. Fetch Macros Timeline
      final macroResponse = await _apiService.get(
        ApiConstants.macrosTimeline,
        queryParameters: {'days': days},
      );
      List<MacroPoint> macroList = [];
      if (macroResponse.success && macroResponse.data != null) {
        final data = macroResponse.data as Map<String, dynamic>;
        final list = data['timeline'] as List? ?? [];
        macroList = list.map((e) => MacroPoint.fromJson(e as Map<String, dynamic>)).toList();
      }

      // 4. Fetch Weight Timeline
      final weightResponse = await _apiService.get(
        ApiConstants.weightTimeline,
        queryParameters: {'days': days},
      );
      List<WeightPoint> weightList = [];
      if (weightResponse.success && weightResponse.data is List) {
        final list = weightResponse.data as List;
        weightList = list.map((e) => WeightPoint.fromJson(e as Map<String, dynamic>)).toList();
      }

      state = state.copyWith(
        isLoading: false,
        streak: streak,
        caloriesTimeline: calList,
        macrosTimeline: macroList,
        weightTimeline: weightList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("ApiException: ", ""),
      );
    }
  }

  Future<bool> logWeight({required double weightKg, String? note}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.weight,
        data: {
          'weight_kg': weightKg,
          'note': note,
        },
      );

      if (response.success) {
        // Reload weight timeline
        await fetchProgressData();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

// Progress provider declaration
final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authStateProvider);

  // Listen for auth state changes to clear summary on logout
  ref.listen(authStateProvider, (previous, next) {
    if (next == AuthState.unauthenticated) {
      ref.invalidateSelf();
    }
  });

  final notifier = ProgressNotifier(apiService);
  if (authState == AuthState.authenticated) {
    // Auto load 7d data
    notifier.fetchProgressData(periodDays: 7);
  }
  return notifier;
});
