import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';
import 'package:frontend/features/diary/providers/diary_provider.dart';

class AddExercisePage extends ConsumerStatefulWidget {
  const AddExercisePage({super.key});

  @override
  ConsumerState<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends ConsumerState<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  
  double _durationMinutes = 30.0;
  String _exerciseType = 'cardio';
  bool _isSaving = false;

  // Pre-configured workout options with their estimated kcal burn rate per minute
  final List<Map<String, dynamic>> _popularExercises = [
    {'name': 'Running (Moderate)', 'rate': 11.4, 'type': 'cardio', 'icon': LucideIcons.flame},
    {'name': 'Outdoor Cycling', 'rate': 8.0, 'type': 'cardio', 'icon': LucideIcons.bike},
    {'name': 'Weightlifting / Resistance', 'rate': 5.0, 'type': 'strength', 'icon': LucideIcons.dumbbell},
    {'name': 'Swimming (Freestyle)', 'rate': 9.8, 'type': 'cardio', 'icon': LucideIcons.droplets},
    {'name': 'Yoga / Pilates', 'rate': 3.5, 'type': 'strength', 'icon': LucideIcons.heartHandshake},
  ];

  @override
  void initState() {
    super.initState();
    // Default to the first popular exercise
    _selectPreset(_popularExercises[0]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _selectPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _exerciseType = preset['type'] as String;
      _updateEstimatedCalories(preset['rate'] as double);
    });
  }

  void _updateEstimatedCalories(double rate) {
    final calculated = rate * _durationMinutes;
    _caloriesController.text = calculated.round().toString();
  }

  // Auto calculate when duration slider slides
  void _onDurationChanged(double val) {
    setState(() {
      _durationMinutes = val;
      // Recalculate using active rate
      final activePreset = _popularExercises.firstWhere(
        (p) => p['name'] == _nameController.text,
        orElse: () => {'rate': _exerciseType == 'cardio' ? 8.0 : 4.0},
      );
      _updateEstimatedCalories(activePreset['rate'] as double);
    });
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(ref.read(summaryProvider).selectedDate);

      final response = await apiService.post(
        ApiConstants.exercises,
        data: {
          'exercise_name': _nameController.text.trim(),
          'duration_minutes': _durationMinutes,
          'calories_burned': double.tryParse(_caloriesController.text) ?? 150.0,
          'exercise_type': _exerciseType,
          'log_date': dateStr,
        },
      );

      if (response.success) {
        // Refresh summary + details
        ref.read(summaryProvider.notifier).fetchSummary();
        ref.read(diaryProvider.notifier).fetchDiaryDetails(ref.read(summaryProvider).selectedDate);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accent,
            content: Text(
              "Logged exercise: ${_nameController.text}!",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        context.pop();
      } else {
        throw ApiException(response.error ?? "Failed to save exercise.");
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceAll("ApiException: ", "")),
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
          "Log Exercise",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick presets horizontal scroller
                Text(
                  "Popular Workouts",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildPresetsList(),
                const SizedBox(height: 28),

                // Form Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workout name field
                      Text(
                        "Exercise Name",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? "Name is required" : null,
                        decoration: const InputDecoration(
                          hintText: "E.g. Running, Pushups...",
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Exercise type selector
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Cardio", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                              value: 'cardio',
                              groupValue: _exerciseType,
                              activeColor: AppColors.accent,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _exerciseType = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text("Strength", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                              value: 'strength',
                              groupValue: _exerciseType,
                              activeColor: AppColors.accent,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _exerciseType = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Duration slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Duration",
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "${_durationMinutes.round()} minutes",
                            style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Slider(
                        value: _durationMinutes,
                        min: 5,
                        max: 120,
                        divisions: 23,
                        activeColor: AppColors.accent,
                        inactiveColor: AppColors.darkBorder,
                        onChanged: _onDurationChanged,
                      ),
                      const SizedBox(height: 12),

                      // Calories burned estimation input
                      Text(
                        "Calories Burned (kcal)",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? "Calories are required" : null,
                        decoration: const InputDecoration(
                          hintText: "E.g. 250",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save exercise button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Log Workout",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _popularExercises.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = _popularExercises[index];
          final isSelected = _nameController.text == preset['name'];
          
          return InkWell(
            onTap: () => _selectPreset(preset),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withOpacity(0.12) : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.darkBorder,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    preset['icon'] as IconData,
                    color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preset['name'] as String,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
