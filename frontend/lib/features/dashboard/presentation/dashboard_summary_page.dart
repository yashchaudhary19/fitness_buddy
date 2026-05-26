import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';

class DashboardSummaryPage extends ConsumerWidget {
  const DashboardSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(summaryProvider);
    final notifier = ref.read(summaryProvider.notifier);

    // Format date header
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final selectedStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    
    String dateHeader = DateFormat('EEEE, MMM d').format(state.selectedDate);
    if (selectedStr == todayStr) {
      dateHeader = "Today";
    } else if (selectedStr == DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)))) {
      dateHeader = "Yesterday";
    } else if (selectedStr == DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)))) {
      dateHeader = "Tomorrow";
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: notifier.fetchSummary,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Date Navigation Bar
            _buildDateNavigator(context, dateHeader, state.selectedDate, notifier),
            
            Expanded(
              child: state.isLoading && state.summary == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.errorMessage != null && state.summary == null
                      ? _buildErrorView(state.errorMessage!, notifier)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: notifier.fetchSummary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
                            child: Column(
                              children: [
                                // Glowing circular calories ring
                                _buildCalorieRingCard(state.summary!),
                                const SizedBox(height: 24),
                                
                                // Macros details bars
                                _buildMacrosCard(state.summary!),
                                const SizedBox(height: 24),
                                
                                // Hydration tracking card
                                _buildWaterCard(context, state.summary!, notifier),
                                const SizedBox(height: 24),
                                
                                // Workouts/Exercise tracking card
                                _buildExerciseCard(state.summary!),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateNavigator(
    BuildContext context,
    String dateHeader,
    DateTime selectedDate,
    SummaryNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => notifier.incrementDate(-1),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                notifier.changeDate(picked);
              }
            },
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  dateHeader,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
            onPressed: () => notifier.incrementDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRingCard(DiarySummary summary) {
    final double percent = summary.caloriesGoal > 0
        ? (summary.caloriesConsumed / (summary.caloriesGoal + summary.exerciseCaloriesBurned)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          // Circular Progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 10,
                  color: AppColors.primary,
                  backgroundColor: AppColors.darkBorder,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary.caloriesRemaining.round().toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Remaining",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 32),
          
          // Calories calculation list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalorieStatRow(LucideIcons.target, "Goal", summary.caloriesGoal.round().toString(), Colors.white),
                const SizedBox(height: 12),
                _buildCalorieStatRow(LucideIcons.apple, "Food", summary.caloriesConsumed.round().toString(), AppColors.primary),
                const SizedBox(height: 12),
                _buildCalorieStatRow(LucideIcons.flame, "Exercise", summary.exerciseCaloriesBurned.round().toString(), AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMacrosCard(DiarySummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Macronutrients",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // Carbohydrates
          _buildMacroProgressBar(
            label: "Carbohydrates",
            consumed: summary.carbsConsumedG,
            goal: summary.carbsGoalG,
            color: AppColors.secondary,
            unit: "g",
          ),
          const SizedBox(height: 16),
          
          // Protein
          _buildMacroProgressBar(
            label: "Protein",
            consumed: summary.proteinConsumedG,
            goal: summary.proteinGoalG,
            color: AppColors.primary,
            unit: "g",
          ),
          const SizedBox(height: 16),
          
          // Fats
          _buildMacroProgressBar(
            label: "Fats",
            consumed: summary.fatConsumedG,
            goal: summary.fatGoalG,
            color: AppColors.accent,
            unit: "g",
          ),
          const SizedBox(height: 16),
          
          // Fiber
          _buildMacroProgressBar(
            label: "Fiber",
            consumed: summary.fiberConsumedG,
            goal: summary.fiberGoalG,
            color: Colors.brown.shade300,
            unit: "g",
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required double consumed,
    required double goal,
    required Color color,
    required String unit,
  }) {
    final double fraction = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13)),
            Text(
              "${consumed.round()} / ${goal.round()} $unit",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.darkBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterCard(BuildContext context, DiarySummary summary, SummaryNotifier notifier) {
    final double percent = summary.waterGoalMl > 0
        ? (summary.waterConsumedMl / summary.waterGoalMl).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/log-water'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.droplets, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      "Water Hydration",
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  "${summary.waterConsumedMl.round()} / ${summary.waterGoalMl.round()} ml",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                color: Colors.blueAccent,
                backgroundColor: AppColors.darkBorder,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => notifier.addWaterQuick(250),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.15),
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(color: Colors.blueAccent, width: 1),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(
                    "Log 250ml",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(DiarySummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.flame, color: AppColors.accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Exercise & Cardio",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Burn extra calories to offset your diet budget.",
                  style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                summary.exerciseCaloriesBurned.round().toString(),
                style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                "kcal",
                style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, SummaryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertOctagon, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: notifier.fetchSummary,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
