import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';
import 'package:frontend/features/diary/providers/diary_provider.dart';

// --- DATA MODEL ---

class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final String? barcode;

  FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.barcode,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Food',
      brand: json['brand']?.toString(),
      caloriesPer100g: (json['calories_per_100g'] as num? ?? 0.0).toDouble(),
      carbsG: (json['carbs_per_100g'] as num? ?? json['carbs_g'] as num? ?? 0.0).toDouble(),
      proteinG: (json['protein_per_100g'] as num? ?? json['protein_g'] as num? ?? 0.0).toDouble(),
      fatG: (json['fat_per_100g'] as num? ?? json['fat_g'] as num? ?? 0.0).toDouble(),
      barcode: json['barcode']?.toString(),
    );
  }
}

// --- STATE MANAGEMENT ---

class SearchState {
  final bool isLoading;
  final String? errorMessage;
  final List<FoodItem> results;

  SearchState({
    this.isLoading = false,
    this.errorMessage,
    required this.results,
  });

  SearchState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<FoodItem>? results,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      results: results ?? this.results,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _apiService;
  final Ref _ref;

  SearchNotifier(this._apiService, this._ref) : super(SearchState(results: []));

  Future<void> searchFoods(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.get(
        ApiConstants.searchFoods,
        queryParameters: {'query': query},
      );

      if (response.success && response.data is List) {
        final list = response.data as List;
        final foods = list.map((item) => FoodItem.fromJson(item as Map<String, dynamic>)).toList();
        state = state.copyWith(isLoading: false, results: foods);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.error ?? "Failed to search foods.");
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("ApiException: ", ""),
      );
    }
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.get("${ApiConstants.barcodeLookup}/$barcode");
      state = state.copyWith(isLoading: false);
      if (response.success && response.data != null) {
        return FoodItem.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Barcode lookup failed: ${e.toString().replaceAll("ApiException: ", "")}",
      );
    }
    return null;
  }

  Future<bool> logFood({
    required FoodItem food,
    required double servingSizeG,
    required String mealType,
    required String logDate,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.diaryEntries,
        data: {
          'food_item_id': food.id,
          'serving_size_g': servingSizeG,
          'meal_type': mealType,
          'log_date': logDate,
        },
      );

      if (response.success) {
        // Trigger refreshes for summary dashboard & diary details!
        _ref.read(summaryProvider.notifier).fetchSummary();
        _ref.read(diaryProvider.notifier).fetchDiaryDetails(_ref.read(summaryProvider).selectedDate);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error logging food: $e");
      }
      // Set the error on the search state so the UI could technically see it
      state = state.copyWith(errorMessage: e.toString().replaceAll("ApiException: ", ""));
    }
    return false;
  }
}

// Search Provider declaration
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SearchNotifier(apiService, ref);
});
