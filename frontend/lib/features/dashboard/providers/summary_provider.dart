import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/router/router.dart';

class DiarySummary {
  final double caloriesGoal;
  final double caloriesConsumed;
  final double exerciseCaloriesBurned;
  final double netCalories;
  final double caloriesRemaining;
  final double proteinGoalG;
  final double proteinConsumedG;
  final double carbsGoalG;
  final double carbsConsumedG;
  final double fatGoalG;
  final double fatConsumedG;
  final double fiberGoalG;
  final double fiberConsumedG;
  final double waterGoalMl;
  final double waterConsumedMl;

  DiarySummary({
    required this.caloriesGoal,
    required this.caloriesConsumed,
    required this.exerciseCaloriesBurned,
    required this.netCalories,
    required this.caloriesRemaining,
    required this.proteinGoalG,
    required this.proteinConsumedG,
    required this.carbsGoalG,
    required this.carbsConsumedG,
    required this.fatGoalG,
    required this.fatConsumedG,
    required this.fiberGoalG,
    required this.fiberConsumedG,
    required this.waterGoalMl,
    required this.waterConsumedMl,
  });

  factory DiarySummary.fromJson(Map<String, dynamic> json) {
    double toDoubleSafe(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) {
        if (val.isNaN || val.isInfinite) return fallback;
        return val.toDouble();
      }
      return fallback;
    }

    return DiarySummary(
      caloriesGoal: toDoubleSafe(json['calories_goal'], 2000),
      caloriesConsumed: toDoubleSafe(json['calories_consumed'], 0),
      exerciseCaloriesBurned: toDoubleSafe(json['exercise_calories_burned'], 0),
      netCalories: toDoubleSafe(json['net_calories'], 0),
      caloriesRemaining: toDoubleSafe(json['calories_remaining'], 2000),
      proteinGoalG: toDoubleSafe(json['protein_goal'], 150),
      proteinConsumedG: toDoubleSafe(json['protein_consumed'], 0),
      carbsGoalG: toDoubleSafe(json['carbs_goal'], 200),
      carbsConsumedG: toDoubleSafe(json['carbs_consumed'], 0),
      fatGoalG: toDoubleSafe(json['fat_goal'], 65),
      fatConsumedG: toDoubleSafe(json['fat_consumed'], 0),
      fiberGoalG: toDoubleSafe(json['fiber_goal'], 25),
      fiberConsumedG: toDoubleSafe(json['fiber_consumed'], 0),
      waterGoalMl: toDoubleSafe(json['water_goal'], 2000),
      waterConsumedMl: toDoubleSafe(json['water_consumed'], 0),
    );
  }

  DiarySummary copyWith({
    double? caloriesGoal,
    double? caloriesConsumed,
    double? exerciseCaloriesBurned,
    double? netCalories,
    double? caloriesRemaining,
    double? proteinGoalG,
    double? proteinConsumedG,
    double? carbsGoalG,
    double? carbsConsumedG,
    double? fatGoalG,
    double? fatConsumedG,
    double? fiberGoalG,
    double? fiberConsumedG,
    double? waterGoalMl,
    double? waterConsumedMl,
  }) {
    return DiarySummary(
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      exerciseCaloriesBurned: exerciseCaloriesBurned ?? this.exerciseCaloriesBurned,
      netCalories: netCalories ?? this.netCalories,
      caloriesRemaining: caloriesRemaining ?? this.caloriesRemaining,
      proteinGoalG: proteinGoalG ?? this.proteinGoalG,
      proteinConsumedG: proteinConsumedG ?? this.proteinConsumedG,
      carbsGoalG: carbsGoalG ?? this.carbsGoalG,
      carbsConsumedG: carbsConsumedG ?? this.carbsConsumedG,
      fatGoalG: fatGoalG ?? this.fatGoalG,
      fatConsumedG: fatConsumedG ?? this.fatConsumedG,
      fiberGoalG: fiberGoalG ?? this.fiberGoalG,
      fiberConsumedG: fiberConsumedG ?? this.fiberConsumedG,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      waterConsumedMl: waterConsumedMl ?? this.waterConsumedMl,
    );
  }
}

class SummaryState {
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;
  final DiarySummary? summary;

  SummaryState({
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
    this.summary,
  });

  SummaryState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DiarySummary? summary,
  }) {
    return SummaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      summary: summary ?? this.summary,
    );
  }
}

class SummaryNotifier extends StateNotifier<SummaryState> {
  final ApiService _apiService;

  SummaryNotifier(this._apiService) : super(SummaryState(selectedDate: DateTime.now()));

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(state.selectedDate);

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.get(
        ApiConstants.diarySummary,
        queryParameters: {'log_date': _formattedDate},
      );
      
      if (!mounted) return;

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          summary: DiarySummary.fromJson(response.data as Map<String, dynamic>),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? "Failed to fetch summary stats.",
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        String displayError = errorStr.replaceAll("ApiException: ", "");
        
        if (errorStr.contains("Connection refused") || errorStr.contains("SocketException")) {
          displayError = "Connection failed. Run 'adb reverse tcp:8000 tcp:8000'";
        }

        state = state.copyWith(
          isLoading: false,
          errorMessage: displayError,
        );
      }
    }
  }

  void changeDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    fetchSummary();
  }

  void incrementDate(int days) {
    changeDate(state.selectedDate.add(Duration(days: days)));
  }

  Future<void> addWaterQuick(int amountMl) async {
    // Optimistic local update
    if (state.summary != null) {
      final updatedSummary = state.summary!.copyWith(
        waterConsumedMl: state.summary!.waterConsumedMl + amountMl,
      );
      state = state.copyWith(summary: updatedSummary);
    }

    try {
      await _apiService.post(
        ApiConstants.water,
        data: {
          'amount_ml': amountMl,
          'log_date': _formattedDate,
        },
      );
      // Refresh to ensure absolute sync with server
      await fetchSummary();
    } catch (e) {
      // Revert optimistic update on failure
      if (state.summary != null) {
        final revertedSummary = state.summary!.copyWith(
          waterConsumedMl: state.summary!.waterConsumedMl - amountMl,
        );
        state = state.copyWith(
          summary: revertedSummary,
          errorMessage: "Failed to record water: ${e.toString()}",
        );
      }
    }
  }
}

// Summary Provider declaration
final summaryProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  // Listen for auth state changes to clear summary on logout
  ref.listen(authStateProvider, (previous, next) {
    if (next == AuthState.unauthenticated) {
      ref.invalidateSelf();
    }
  });

  final notifier = SummaryNotifier(apiService);
  if (authState == AuthState.authenticated) {
    notifier.fetchSummary();
  }
  return notifier;
});
