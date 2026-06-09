import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/router/router.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';

// --- DATA MODELS ---

class DiaryFoodEntry {
  final String id;
  final String foodName;
  final String? brandName;
  final double servingSizeG;
  final double calories;
  final double carbsG;
  final double proteinG;
  final double fatG;

  DiaryFoodEntry({
    required this.id,
    required this.foodName,
    this.brandName,
    required this.servingSizeG,
    required this.calories,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  factory DiaryFoodEntry.fromJson(Map<String, dynamic> json) {
    final foodItem = json['food_item'] as Map<String, dynamic>? ?? {};
    return DiaryFoodEntry(
      id: json['id']?.toString() ?? '',
      foodName: foodItem['name']?.toString() ?? 'Unknown Food',
      brandName: foodItem['brand']?.toString(),
      servingSizeG: (json['serving_size_g'] as num? ?? 100.0).toDouble(),
      calories: (json['calories'] as num? ?? 0.0).toDouble(),
      carbsG: (json['carbs_g'] as num? ?? 0.0).toDouble(),
      proteinG: (json['protein_g'] as num? ?? 0.0).toDouble(),
      fatG: (json['fat_g'] as num? ?? 0.0).toDouble(),
    );
  }
}

class MealSectionData {
  final List<DiaryFoodEntry> entries;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  MealSectionData({
    required this.entries,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory MealSectionData.empty() {
    return MealSectionData(entries: [], totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0);
  }

  factory MealSectionData.fromJson(Map<String, dynamic> json) {
    final list = json['entries'] as List? ?? [];
    final entries = list
        .map((item) => DiaryFoodEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    return MealSectionData(
      entries: entries,
      totalCalories: (json['total_calories'] as num? ?? 0.0).toDouble(),
      totalProtein: (json['total_protein'] as num? ?? 0.0).toDouble(),
      totalCarbs: (json['total_carbs'] as num? ?? 0.0).toDouble(),
      totalFat: (json['total_fat'] as num? ?? 0.0).toDouble(),
    );
  }
}

class DiaryExerciseEntry {
  final String id;
  final String name;
  final String type; // cardio, strength
  final double durationMinutes;
  final double caloriesBurned;

  DiaryExerciseEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  factory DiaryExerciseEntry.fromJson(Map<String, dynamic> json) {
    return DiaryExerciseEntry(
      id: json['id']?.toString() ?? '',
      name: json['exercise_name']?.toString() ?? 'Exercise',
      type: json['exercise_type']?.toString() ?? 'cardio',
      durationMinutes: (json['duration_minutes'] as num? ?? 0.0).toDouble(),
      caloriesBurned: (json['calories_burned'] as num? ?? 0.0).toDouble(),
    );
  }
}

// --- STATE MANAGEMENT ---

class DiaryState {
  final bool isLoading;
  final String? errorMessage;
  
  // Meals grouped
  final Map<String, MealSectionData> meals;
  final List<DiaryExerciseEntry> exercises;
  final double totalExerciseCalories;

  DiaryState({
    this.isLoading = false,
    this.errorMessage,
    required this.meals,
    required this.exercises,
    this.totalExerciseCalories = 0.0,
  });

  factory DiaryState.initial() {
    return DiaryState(
      meals: {
        'breakfast': MealSectionData.empty(),
        'lunch': MealSectionData.empty(),
        'dinner': MealSectionData.empty(),
        'snacks': MealSectionData.empty(),
      },
      exercises: [],
    );
  }

  DiaryState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Map<String, MealSectionData>? meals,
    List<DiaryExerciseEntry>? exercises,
    double? totalExerciseCalories,
  }) {
    return DiaryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      meals: meals ?? this.meals,
      exercises: exercises ?? this.exercises,
      totalExerciseCalories: totalExerciseCalories ?? this.totalExerciseCalories,
    );
  }
}

class DiaryNotifier extends StateNotifier<DiaryState> {
  final ApiService _apiService;
  final Ref _ref;
  final DateTime _selectedDate;

  DiaryNotifier(this._apiService, this._ref, this._selectedDate) : super(DiaryState.initial()) {
    // Only fetch if we're authenticated to avoid 401 loops
    final authState = _ref.read(authStateProvider);
    if (authState == AuthState.authenticated) {
      fetchDiaryDetails(_selectedDate);
    }
  }

  Future<void> fetchDiaryDetails(DateTime date) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    if (kDebugMode) {
      print("Fetching diary details for $dateStr...");
    }

    try {
      // Fetch both food and exercises in parallel for performance
      final results = await Future.wait([
        _apiService.get(ApiConstants.diary, queryParameters: {'log_date': dateStr}),
        _apiService.get(ApiConstants.exercises, queryParameters: {'log_date': dateStr}),
      ]);

      if (kDebugMode) {
        print("Diary responses received: ${results[0].success}, ${results[1].success}");
      }

      final diaryResponse = results[0];
      final exerciseResponse = results[1];

      Map<String, MealSectionData> parsedMeals = {
        'breakfast': MealSectionData.empty(),
        'lunch': MealSectionData.empty(),
        'dinner': MealSectionData.empty(),
        'snacks': MealSectionData.empty(),
      };

      if (diaryResponse.success && diaryResponse.data != null) {
        final resData = diaryResponse.data as Map<String, dynamic>;
        final mealsMap = resData['meals'] as Map<String, dynamic>? ?? {};
        
        mealsMap.forEach((mealType, mealData) {
          if (parsedMeals.containsKey(mealType)) {
            parsedMeals[mealType] = MealSectionData.fromJson(mealData as Map<String, dynamic>);
          }
        });
      }

      List<DiaryExerciseEntry> parsedExercises = [];
      double totalBurned = 0.0;

      if (exerciseResponse.success && exerciseResponse.data is List) {
        final list = exerciseResponse.data as List;
        parsedExercises = list.map((item) => DiaryExerciseEntry.fromJson(item as Map<String, dynamic>)).toList();
        totalBurned = parsedExercises.fold(0.0, (sum, item) => sum + item.caloriesBurned);
      }

      state = state.copyWith(
        isLoading: false,
        meals: parsedMeals,
        exercises: parsedExercises,
        totalExerciseCalories: totalBurned,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching diary details: $e");
      }
      // Only set error if we are still mounted and relevant
      if (mounted) {
        final errorStr = e.toString();
        String displayError = errorStr.replaceAll("ApiException: ", "");
        
        if (errorStr.contains("Connection refused") || errorStr.contains("SocketException")) {
          displayError = "Connection to server failed. Please check your internet connection.";
        }

        state = state.copyWith(
          isLoading: false,
          errorMessage: displayError,
        );
      }
    }
  }

  Future<void> deleteFoodEntry(String entryId) async {
    // Optimistically update the UI state by removing the item immediately
    final updatedMeals = Map<String, MealSectionData>.from(state.meals);
    String? foundMealType;

    for (var mealType in updatedMeals.keys) {
      final entries = List<DiaryFoodEntry>.from(updatedMeals[mealType]!.entries);
      final index = entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        entries.removeAt(index);
        foundMealType = mealType;
        
        // Recalculate totals for this meal section
        final totalCalories = entries.fold(0.0, (sum, item) => sum + item.calories);
        final totalProtein = entries.fold(0.0, (sum, item) => sum + item.proteinG);
        final totalCarbs = entries.fold(0.0, (sum, item) => sum + item.carbsG);
        final totalFat = entries.fold(0.0, (sum, item) => sum + item.fatG);

        updatedMeals[mealType] = MealSectionData(
          entries: entries,
          totalCalories: totalCalories,
          totalProtein: totalProtein,
          totalCarbs: totalCarbs,
          totalFat: totalFat,
        );
        break;
      }
    }

    if (foundMealType != null) {
      state = state.copyWith(meals: updatedMeals);
    }

    try {
      final response = await _apiService.delete("${ApiConstants.diaryEntries}/$entryId");
      if (response.success) {
        // Trigger dashboard metrics recalculation
        _ref.read(summaryProvider.notifier).fetchSummary();
        // Refresh diary details to ensure local state matches the DB exactly
        final currentDate = _ref.read(summaryProvider).selectedDate;
        await fetchDiaryDetails(currentDate);
      } else {
        throw Exception(response.error ?? "Failed to delete food entry");
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: "Failed to delete food entry: ${e.toString().replaceAll("Exception: ", "")}",
      );
      // Re-fetch to restore the item since deletion failed
      final currentDate = _ref.read(summaryProvider).selectedDate;
      fetchDiaryDetails(currentDate);
    }
  }

  Future<void> deleteExerciseEntry(String logId) async {
    // Optimistically update the UI state by removing the item immediately
    final updatedExercises = List<DiaryExerciseEntry>.from(state.exercises);
    final index = updatedExercises.indexWhere((e) => e.id == logId);
    double deletedCalories = 0.0;
    if (index != -1) {
      deletedCalories = updatedExercises[index].caloriesBurned;
      updatedExercises.removeAt(index);
      state = state.copyWith(
        exercises: updatedExercises,
        totalExerciseCalories: state.totalExerciseCalories - deletedCalories,
      );
    }

    try {
      final response = await _apiService.delete("${ApiConstants.exercises}$logId");
      if (response.success) {
        // Trigger dashboard metrics recalculation
        _ref.read(summaryProvider.notifier).fetchSummary();
        // Refresh diary details to ensure local state matches the DB exactly
        final currentDate = _ref.read(summaryProvider).selectedDate;
        await fetchDiaryDetails(currentDate);
      } else {
        throw Exception(response.error ?? "Failed to delete exercise entry");
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: "Failed to delete exercise entry: ${e.toString().replaceAll("Exception: ", "")}",
      );
      // Re-fetch to restore the item since deletion failed
      final currentDate = _ref.read(summaryProvider).selectedDate;
      fetchDiaryDetails(currentDate);
    }
  }
}

// Diary Provider declaration
final diaryProvider = StateNotifierProvider<DiaryNotifier, DiaryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final selectedDate = ref.watch(summaryProvider.select((s) => s.selectedDate));
  ref.watch(authStateProvider); // Recreate provider if auth state changes

  return DiaryNotifier(apiService, ref, selectedDate);
});
