import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';
import 'package:frontend/features/diary/providers/diary_provider.dart';
import 'package:frontend/core/ads/ad_service.dart';

class ScanMealPage extends ConsumerStatefulWidget {
  const ScanMealPage({super.key});

  @override
  ConsumerState<ScanMealPage> createState() => _ScanMealPageState();
}

class _ScanMealPageState extends ConsumerState<ScanMealPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _isLogging = false;
  int _loadingStage = 1;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routerState = GoRouterState.of(context);
      setState(() {
        _mealType = routerState.uri.queryParameters['meal_type'] ?? 'breakfast';
      });
    });
    _mealType = 'breakfast'; // safe initial value
  }
  
  // Results from AI analysis
  Map<String, dynamic>? _analysisResults;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _analysisResults = null; // Clear previous analysis
        });
        if (mounted) {
          await Future.microtask(_analyzeMeal);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text("Error picking image: $e"),
        ),
      );
    }
  }

  Future<void> _analyzeMeal() async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _loadingStage = 1;
    });

    final loadingTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _isAnalyzing) {
        setState(() {
          _loadingStage = 2;
        });
      }
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final bytes = await _selectedImage!.readAsBytes();
      
      if (kDebugMode) {
        debugPrint("Uploading meal image for AI scan...");
      }

      final response = await apiService.upload(
        ApiConstants.mealScan,
        bytes,
        "meal_photo.jpg",
        mimeType: "image/jpeg",
      );

      loadingTimer.cancel();

      if (response.success && response.data != null) {
        setState(() {
          _analysisResults = response.data as Map<String, dynamic>;
          _isAnalyzing = false;
        });
      } else {
        throw ApiException(response.error ?? "Failed to analyze meal photo.");
      }
    } catch (e) {
      loadingTimer.cancel();
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceAll("ApiException: ", "")),
        ),
      );
    }
  }

  Future<void> _logMealToDiary() async {
    if (_analysisResults == null) return;

    setState(() {
      _isLogging = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(ref.read(summaryProvider).selectedDate);
      final detectedItems = _analysisResults!['items'] as List? ?? [];

      // Log each detected item to the diary
      for (final item in detectedItems) {
        final Map<String, dynamic> itemMap = item as Map<String, dynamic>;

        // 1. Create custom food first
        final foodResponse = await apiService.post(
          ApiConstants.customFood,
          data: {
            'name': itemMap['name'],
            'brand': 'AI Scanned',
            'calories_per_100g': (itemMap['calories_per_100g'] as num? ?? 0.0).toDouble(),
            'carbs_per_100g': (itemMap['carbs_per_100g'] as num? ?? 0.0).toDouble(),
            'protein_per_100g': (itemMap['protein_per_100g'] as num? ?? 0.0).toDouble(),
            'fat_per_100g': (itemMap['fat_per_100g'] as num? ?? 0.0).toDouble(),
            'fiber_per_100g': 0.0,
            'sugar_per_100g': 0.0,
            'sodium_per_100g': 0.0,
            'saturated_fat_per_100g': 0.0,
          },
        );

        if (foodResponse.success && foodResponse.data != null) {
          final createdFood = foodResponse.data as Map<String, dynamic>;
          final foodId = createdFood['id'];

          // 2. Log entry with foodId
          await apiService.post(
            ApiConstants.diaryEntries,
            data: {
              'food_item_id': foodId,
              'serving_size_g': (itemMap['estimated_grams'] as num? ?? 100.0).toDouble(),
              'meal_type': _mealType,
              'log_date': dateStr,
            },
          );
        } else {
          throw ApiException(foodResponse.error ?? "Failed to save scanned food item.");
        }
      }

      // Refresh providers
      ref.read(summaryProvider.notifier).fetchSummary();
      ref.read(diaryProvider.notifier).fetchDiaryDetails(ref.read(summaryProvider).selectedDate);

      setState(() {
        _isLogging = false;
      });

      // Show interstitial ad, then pop the screen and show success SnackBar
      AdService.showInterstitial(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content: Text(
                "Logged AI analyzed items to $_mealType!",
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
          context.pop(); // Return to search/diary
        }
      });
    } catch (e) {
      setState(() {
        _isLogging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text("Error logging items: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "AI Scan → ${_mealType[0].toUpperCase()}${_mealType.substring(1)}",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Viewer Viewport
              _buildImageViewport(),
              const SizedBox(height: 24),

              if (_selectedImage != null && _analysisResults == null && !_isAnalyzing) ...[
                const SizedBox(height: 8),
                // Analyze button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _analyzeMeal,
                    icon: const Icon(LucideIcons.sparkles, color: Colors.black),
                    label: Text(
                      "Analyze with AI",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],

              if (_isAnalyzing) ...[
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _loadingStage == 1
                            ? "AI scanning meal photo..."
                            : "AI estimating portions & macros...",
                        style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              if (_analysisResults != null) ...[
                // Analysis display panels
                _buildAnalysisReport(),
                const SizedBox(height: 24),
                
                // Confirm & Log button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLogging ? null : _logMealToDiary,
                    child: _isLogging
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            "Log items to ${_mealType.toUpperCase()}",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildImageViewport() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _selectedImage != null
            ? Image.file(
                File(_selectedImage!.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.camera, size: 48, color: AppColors.darkBorder),
                    const SizedBox(height: 16),
                    Text(
                      "Take or Upload a Food Photo",
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(LucideIcons.camera, size: 16, color: Colors.black),
                          label: const Text("Camera"),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          icon: const Icon(LucideIcons.image, size: 16),
                          label: const Text("Gallery"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Log to which meal?",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['breakfast', 'lunch', 'dinner', 'snacks'].map((meal) {
            final isSelected = _mealType == meal;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text(
                    "${meal[0].toUpperCase()}${meal.substring(1)}",
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  onSelected: (_) => setState(() => _mealType = meal),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.darkSurface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalysisReport() {
    final calories = (_analysisResults!['total_estimated_calories'] as num? ?? 0.0).toDouble();
    final detectedItems = _analysisResults!['items'] as List? ?? [];

    double carbs = 0.0;
    double protein = 0.0;
    double fat = 0.0;

    for (final item in detectedItems) {
      final itemMap = item as Map<String, dynamic>;
      final weight = (itemMap['estimated_grams'] as num? ?? 100.0).toDouble();
      final factor = weight / 100.0;
      carbs += (itemMap['carbs_per_100g'] as num? ?? 0.0).toDouble() * factor;
      protein += (itemMap['protein_per_100g'] as num? ?? 0.0).toDouble() * factor;
      fat += (itemMap['fat_per_100g'] as num? ?? 0.0).toDouble() * factor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Success Banner
        Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              "AI Meal Report",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Core stats panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Calories", style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 15)),
                  Text("${calories.round()} kcal", style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
              ),
              const Divider(color: AppColors.darkBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroDetailItem("Carbs", carbs, AppColors.secondary),
                  _buildMacroDetailItem("Protein", protein, AppColors.primary),
                  _buildMacroDetailItem("Fats", fat, AppColors.accent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Detected food items list
        Text(
          "Detected Ingredients",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: detectedItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = detectedItems[index] as Map<String, dynamic>;
            final itemWeight = (item['estimated_grams'] as num? ?? 100.0).toDouble();
            final itemCal = (item['calories_per_100g'] as num? ?? 0.0).toDouble() * (itemWeight / 100.0);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Ingredient',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${itemWeight.round()}g portion",
                          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${itemCal.round()} kcal",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMacroDetailItem(String label, double amount, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          "${amount.round()}g",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
