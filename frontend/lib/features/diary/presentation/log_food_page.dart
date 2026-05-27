import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';
import 'package:frontend/features/diary/providers/search_provider.dart';
import 'package:frontend/features/diary/providers/diary_provider.dart';
import 'package:frontend/core/ads/ad_service.dart';
import 'package:frontend/core/ads/obsidian_native_ad_widget.dart';

class LogFoodPage extends ConsumerStatefulWidget {
  const LogFoodPage({super.key});

  @override
  ConsumerState<LogFoodPage> createState() => _LogFoodPageState();
}

class _LogFoodPageState extends ConsumerState<LogFoodPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _mealType = 'breakfast';

  @override
  void initState() {
    super.initState();
    // Fetch meal type query parameter safely after binding frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      setState(() {
        _mealType = state.uri.queryParameters['meal_type'] ?? 'breakfast';
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(searchProvider.notifier).searchFoods(query);
      }
    });
  }

  // --- SERVING SIZE DETAIL BOTTOM SHEET ---

  void _showServingSheet(BuildContext context, FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ServingDetailSheet(
          food: food,
          mealType: _mealType,
          onSuccess: () {
            context.pop(); // Close bottom sheet
            context.pop(); // Return to diary page
            
            // Show Interstitial Ad upon successfully saving the meal log
            AdService.showInterstitial(() {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    "Logged ${food.name} successfully!",
                    style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Log ${_mealType[0].toUpperCase()}${_mealType.substring(1)}",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AI / Camera / Voice Shortcuts Row
            _buildLogShortcuts(context),
            
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.darkTextSecondary),
                  hintText: "Search food name, brand, ingredients...",
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.darkTextSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Search results listing
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.errorMessage != null
                      ? _buildErrorView(state.errorMessage!)
                      : _searchController.text.isEmpty
                          ? _buildEmptySearchPrompt()
                          : state.results.isEmpty
                              ? _buildNoResultsView()
                              : Material(
                                  color: Colors.transparent,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    itemCount: state.results.length + (state.results.length ~/ 4),
                                    separatorBuilder: (context, index) {
                                      final isCurrentAd = (index + 1) % 5 == 0;
                                      final isNextAd = (index + 2) % 5 == 0;
                                      if (isCurrentAd || isNextAd) {
                                        return const SizedBox.shrink();
                                      }
                                      return const Divider(color: AppColors.darkBorder, height: 1);
                                    },
                                    itemBuilder: (context, index) {
                                      final isAd = (index + 1) % 5 == 0;
                                      if (isAd) {
                                        return const ObsidianNativeAdWidget();
                                      }

                                      final originalIndex = index - (index ~/ 5);
                                      if (originalIndex >= state.results.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final food = state.results[originalIndex];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        title: Text(
                                          food.name,
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          food.brand ?? "Generic Brand",
                                          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "${food.caloriesPer100g.round()} kcal",
                                                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  "per 100g",
                                                  style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(LucideIcons.chevronRight, color: AppColors.darkTextSecondary, size: 18),
                                          ],
                                        ),
                                        onTap: () => _showServingSheet(context, food),
                                      );
                                    },
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOG OPTIONS ROW ---

  Widget _buildLogShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        children: [
          // Barcode scanner button
          Expanded(
            child: _buildShortcutButton(
              label: "Barcode",
              icon: LucideIcons.scan,
              color: AppColors.primary,
              onTap: () async {
                final result = await context.push<dynamic>('/scan-barcode');
                if (result is FoodItem && mounted) {
                  _showServingSheet(context, result);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // AI Photo Meal Scanner button
          Expanded(
            child: _buildShortcutButton(
              label: "AI Photo",
              icon: LucideIcons.camera,
              color: AppColors.secondary,
              onTap: () {
                context.push('/scan-meal?meal_type=$_mealType');
              },
            ),
          ),
          const SizedBox(width: 12),
          // AI Voice transcription button
          Expanded(
            child: _buildShortcutButton(
              label: "AI Voice",
              icon: LucideIcons.mic,
              color: AppColors.accent,
              onTap: () {
                _showVoicePanel(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AUXILIARY WIDGETS ---

  Widget _buildEmptySearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48, color: AppColors.darkBorder),
          const SizedBox(height: 16),
          Text(
            "Search for Foods",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Type a food name or try scanning with AI shortcuts above.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.frown, size: 48, color: AppColors.darkBorder),
            const SizedBox(height: 16),
            Text(
              "No foods found",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't find matches. Try scanning a barcode or typing something else.",
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          error,
          style: GoogleFonts.outfit(color: AppColors.error, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Barcode lookup fallback simulation
  void _showBarcodeMockupDialog(BuildContext context) {
    final barcodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text("Scan Barcode", style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter barcode number manually (e.g. 5449000000096 for Coca-Cola, or scan camera):",
                style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: barcodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Enter barcode...",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = barcodeController.text.trim();
                context.pop(); // Close dialog
                if (code.isNotEmpty) {
                  final food = await ref.read(searchProvider.notifier).lookupBarcode(code);
                  if (food != null) {
                    _showServingSheet(context, food);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(
                          "Barcode $code not found on Open Food Facts.",
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text("Search"),
            ),
          ],
        );
      },
    );
  }

  // Voice recognition panel mockup
  void _showVoicePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _VoiceLoggingSheet(mealType: _mealType);
      },
    );
  }
}

// --- SERVING DETAIL SHEET STATEFUL WIDGET ---

class _ServingDetailSheet extends ConsumerStatefulWidget {
  final FoodItem food;
  final String mealType;
  final VoidCallback onSuccess;

  const _ServingDetailSheet({
    required this.food,
    required this.mealType,
    required this.onSuccess,
  });

  @override
  ConsumerState<_ServingDetailSheet> createState() => _ServingDetailSheetState();
}

class _ServingDetailSheetState extends ConsumerState<_ServingDetailSheet> {
  double _servingSizeG = 100.0;
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    // Recalculate nutrient values
    final multiplier = _servingSizeG / 100.0;
    final calories = widget.food.caloriesPer100g * multiplier;
    final carbs = widget.food.carbsG * multiplier;
    final protein = widget.food.proteinG * multiplier;
    final fat = widget.food.fatG * multiplier;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header details
          Text(
            widget.food.name,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            widget.food.brand ?? "Generic Brand",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Numeric Portion input
          Row(
            children: [
              Expanded(
                child: Text(
                  "Serving Size (grams)",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _servingSizeG.round().toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _servingSizeG = parsed;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live Calories display card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Calculated Calories",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "${calories.round()} kcal",
                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Macros sliders
          Text(
            "Nutrient Breakdown",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildMacroRow("Carbohydrates", carbs, AppColors.secondary),
          const SizedBox(height: 10),
          _buildMacroRow("Protein", protein, AppColors.primary),
          const SizedBox(height: 10),
          _buildMacroRow("Fats", fat, AppColors.accent),
          const SizedBox(height: 32),

          // Log Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLogging
                  ? null
                  : () async {
                      setState(() => _isLogging = true);
                      final dateStr = DateFormat('yyyy-MM-dd').format(ref.read(summaryProvider).selectedDate);
                      final success = await ref.read(searchProvider.notifier).logFood(
                            food: widget.food,
                            servingSizeG: _servingSizeG,
                            mealType: widget.mealType,
                            logDate: dateStr,
                          );
                      if (success) {
                        widget.onSuccess();
                      } else {
                        setState(() => _isLogging = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text(
                              "Failed to log food entry. Please try again.",
                              style: GoogleFonts.outfit(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
              child: _isLogging
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      "Log to ${widget.mealType[0].toUpperCase()}${widget.mealType.substring(1)}",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14)),
          ],
        ),
        Text(
          "${amount.toStringAsFixed(1)} g",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

// --- VOICE LOGGING SHEET MOCKUP / AI PANEL ---

class _VoiceLoggingSheet extends ConsumerStatefulWidget {
  final String mealType;

  const _VoiceLoggingSheet({required this.mealType});

  @override
  ConsumerState<_VoiceLoggingSheet> createState() => _VoiceLoggingSheetState();
}

class _VoiceLoggingSheetState extends ConsumerState<_VoiceLoggingSheet> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  final TextEditingController _textController = TextEditingController();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcription = "";
  String _errorMessage = "";
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech recognition error: ${val.errorMsg} (permanent: ${val.permanent})');
          if (mounted) {
            setState(() {
              _errorMessage = "Speech error: ${val.errorMsg}";
              _isRecording = false;
              _waveformController.stop();
            });
          }
        },
        onStatus: (val) {
          debugPrint('Speech recognition status: $val');
          if (val == 'done' || val == 'notListening') {
            if (mounted && _isRecording) {
              setState(() {
                _isRecording = false;
                _waveformController.stop();
              });
            }
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (e) {
      debugPrint('Speech recognition init failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Speech initialization failed: $e";
        });
      }
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _speech.stop();
      _waveformController.stop();
      setState(() {
        _isRecording = false;
      });
    } else {
      if (!_speechEnabled) {
        await _initSpeech();
      }
      
      if (_speechEnabled) {
        _waveformController.repeat();
        setState(() {
          _isRecording = true;
          _errorMessage = "";
        });
        
        await _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textController.text = val.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          listenMode: stt.ListenMode.dictation,
        );
      } else {
        setState(() {
          _errorMessage = "Speech recognition is not available on this device.";
        });
      }
    }
  }

  Future<void> _submitVoiceLog() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = "";
      _transcription = "";
    });

    try {
      final api = ref.read(apiServiceProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(ref.read(summaryProvider).selectedDate);
      
      final response = await api.post(
        ApiConstants.voiceParse,
        data: {
          'transcript': text,
        },
      );

      if (response.success && response.data != null) {
        final parsedItems = response.data['items'] as List? ?? [];
        final List<String> loggedSummaries = [];

        for (final item in parsedItems) {
          final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
          final foodName = itemMap['food_name'] as String;
          final quantityG = (itemMap['quantity_g'] as num? ?? 100.0).toDouble();
          final itemMealType = widget.mealType; // Use the selected meal section

          // Search database for matching food
          final searchResponse = await api.get(
            ApiConstants.searchFoods,
            queryParameters: {'query': foodName},
          );

          String foodId;
          if (searchResponse.success && searchResponse.data is List && (searchResponse.data as List).isNotEmpty) {
            // Use first matching food
            final matchedFood = (searchResponse.data as List).first as Map<String, dynamic>;
            foodId = matchedFood['id'].toString();
          } else {
            // Create a basic custom food if not found, using Gemini's estimated nutritional values if available
            final createResponse = await api.post(
              ApiConstants.customFood,
              data: {
                'name': foodName,
                'brand': 'Voice Added',
                'calories_per_100g': (itemMap['calories_per_100g'] as num? ?? 80.0).toDouble(),
                'carbs_per_100g': (itemMap['carbs_per_100g'] as num? ?? 10.0).toDouble(),
                'protein_per_100g': (itemMap['protein_per_100g'] as num? ?? 2.0).toDouble(),
                'fat_per_100g': (itemMap['fat_per_100g'] as num? ?? 2.0).toDouble(),
                'fiber_per_100g': 0.0,
                'sugar_per_100g': 0.0,
                'sodium_per_100g': 0.0,
                'saturated_fat_per_100g': 0.0,
              },
            );

            if (createResponse.success && createResponse.data != null) {
              foodId = createResponse.data['id'].toString();
            } else {
              continue; // Skip if creation failed
            }
          }

          // Log food log entry
          final logResponse = await api.post(
            ApiConstants.diaryEntries,
            data: {
              'food_item_id': foodId,
              'serving_size_g': quantityG,
              'meal_type': itemMealType,
              'log_date': dateStr,
            },
          );

          if (logResponse.success) {
            loggedSummaries.add("$foodName (${quantityG.round()}g)");
          }
        }

        if (loggedSummaries.isNotEmpty) {
          setState(() {
            _isProcessing = false;
            _transcription = "Success! Logged: ${loggedSummaries.join(', ')}";
          });

          ref.read(summaryProvider.notifier).fetchSummary();
          ref.read(diaryProvider.notifier).fetchDiaryDetails(ref.read(summaryProvider).selectedDate);

          // Show interstitial ad after successful voice log
          if (mounted) {
            AdService.showInterstitial(() {
              // Ad dismissed — sheet stays open showing success message
            });
          }
        } else {
          setState(() {
            _isProcessing = false;
            _transcription = "Could not log parsed voice items.";
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = "AI Voice parse failed: ${response.error}";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Error parsing: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AI Voice & Text Logger",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: AppColors.darkTextSecondary),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Describe what you ate in natural language (e.g. \"I had 2 boiled eggs and an avocado for breakfast\"). AI will parse and log it instantly.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _textController,
              maxLines: 4,
              minLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Speak or type your food log here...",
                hintStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (_transcription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _transcription,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _waveformController,
              builder: (context, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      animationValue: _waveformController.value,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Listening... Speak clearly. Tap mic to stop.",
                style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? AppColors.error : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? LucideIcons.square : LucideIcons.mic,
                    color: _isRecording ? AppColors.error : AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(LucideIcons.trash2, color: AppColors.darkTextSecondary, size: 24),
                onPressed: () {
                  setState(() {
                    _textController.clear();
                    _transcription = "";
                    _errorMessage = "";
                  });
                },
                tooltip: "Clear log",
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing || _isRecording
                  ? null
                  : () {
                      if (_transcription.isNotEmpty) {
                        context.pop();
                      } else {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          _submitVoiceLog();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.darkBorder,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      _transcription.isNotEmpty ? "Close" : "Log with AI",
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WaveformPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final width = size.width;
    const barCount = 35;
    final barSpacing = width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing + 4;
      final progress = i / barCount;
      // Calculate animated bouncing waves using combined sine waves
      final wave = double.parse((0.4 * (1.0 + math.sin(progress * 5.0) * math.cos(animationValue * 2.0 * math.pi))).toStringAsFixed(3));
      final height = (wave.abs() * centerY * 0.9) + 4.0;

      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
