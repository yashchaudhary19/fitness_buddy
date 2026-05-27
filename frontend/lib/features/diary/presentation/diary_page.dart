import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';
import 'package:frontend/features/diary/providers/diary_provider.dart';
import 'package:frontend/core/ads/ad_banner_widget.dart';
import 'package:frontend/core/ads/diary_native_ad_widget.dart';

class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryProvider);
    final notifier = ref.read(diaryProvider.notifier);
    final summaryState = ref.watch(summaryProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Nutrition Diary",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current Selected Date indicator banner
            _buildDateBanner(context, summaryState.selectedDate),

            Expanded(
              child: state.isLoading && state.meals['breakfast']!.entries.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.errorMessage != null && state.meals['breakfast']!.entries.isEmpty
                      ? _buildErrorView(state.errorMessage!, summaryState.selectedDate, notifier)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => notifier.fetchDiaryDetails(summaryState.selectedDate),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
                            child: Column(
                              children: [
                                // Breakfast Card
                                _buildMealSectionCard(context, "Breakfast", "breakfast", state.meals['breakfast']!, notifier),
                                const SizedBox(height: 18),
                                
                                // Lunch Card
                                _buildMealSectionCard(context, "Lunch", "lunch", state.meals['lunch']!, notifier),
                                const SizedBox(height: 18),
                                
                                // Dinner Card
                                _buildMealSectionCard(context, "Dinner", "dinner", state.meals['dinner']!, notifier),
                                const SizedBox(height: 18),

                                // ── Native Ad between Dinner & Snacks ──
                                const DiaryNativeAdWidget(),
                                const SizedBox(height: 18),

                                // Snacks Card
                                _buildMealSectionCard(context, "Snacks", "snacks", state.meals['snacks']!, notifier),
                                const SizedBox(height: 24),
                                
                                // Exercise Card
                                _buildExerciseSectionCard(context, state.exercises, state.totalExerciseCalories, notifier),
                              ],
                            ),
                          ),
                        ),
            ),
            
            // AdMob Banner / Premium Fallback Promo at the bottom, cleared of floating nav bar
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 108),
              child: AdBannerWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateBanner(BuildContext context, DateTime selectedDate) {
    return Container(
      width: double.infinity,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Center(
        child: Text(
          "Viewing logs for ${DateFormat('MMMM d, yyyy').format(selectedDate)}",
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMealSectionCard(
    BuildContext context,
    String title,
    String mealType,
    MealSectionData data,
    DiaryNotifier notifier,
  ) {
    return Material(
      color: AppColors.darkSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
            initiallyExpanded: true,
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  "${data.totalCalories.round()} kcal",
                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            children: [
              const Divider(color: AppColors.darkBorder, height: 1),
              
              // List of entries
              if (data.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No items logged yet",
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.entries.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.darkBorder, height: 1),
                  itemBuilder: (context, index) {
                    final entry = data.entries[index];
                    return _buildFoodDismissibleRow(entry, notifier);
                  },
                ),

              const Divider(color: AppColors.darkBorder, height: 1),
              
              // Add Food Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/log-food?meal_type=$mealType');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text("Add Food", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildFoodDismissibleRow(DiaryFoodEntry entry, DiaryNotifier notifier) {
    return Dismissible(
      key: ValueKey("food_${entry.id}"),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) => notifier.deleteFoodEntry(entry.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (entry.brandName != null && entry.brandName!.isNotEmpty)
                    Text(
                      entry.brandName!,
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${entry.servingSizeG.round()}g",
                        style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      _buildMacroBadge("C:${entry.carbsG.round()}g", AppColors.secondary),
                      const SizedBox(width: 6),
                      _buildMacroBadge("P:${entry.proteinG.round()}g", AppColors.primary),
                      const SizedBox(width: 6),
                      _buildMacroBadge("F:${entry.fatG.round()}g", AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${entry.calories.round()} kcal",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSectionCard(
    BuildContext context,
    List<DiaryExerciseEntry> exercises,
    double totalBurned,
    DiaryNotifier notifier,
  ) {
    return Material(
      color: AppColors.darkSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
            initiallyExpanded: true,
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Row(
              children: [
                const Icon(LucideIcons.flame, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Text(
                  "Exercise & Cardio",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                Text(
                  "-${totalBurned.round()} kcal",
                  style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            children: [
              const Divider(color: AppColors.darkBorder, height: 1),
              
              if (exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No exercises logged today",
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.darkBorder, height: 1),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Dismissible(
                      key: ValueKey("exercise_${exercise.id}"),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error,
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(LucideIcons.trash2, color: Colors.white),
                      ),
                      onDismissed: (direction) => notifier.deleteExerciseEntry(exercise.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    "${exercise.durationMinutes.round()} mins | ${exercise.type.toUpperCase()}",
                                    style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "-${exercise.caloriesBurned.round()} kcal",
                              style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const Divider(color: AppColors.darkBorder, height: 1),
              
              // Add Exercise Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/add-exercise');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text("Add Exercise", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildMacroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildErrorView(String error, DateTime date, DiaryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              "Could not load diary details",
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
              onPressed: () => notifier.fetchDiaryDetails(date),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
