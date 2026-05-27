import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/ads/ad_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/progress/providers/progress_provider.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _weightInputController = TextEditingController();
  final TextEditingController _noteInputController = TextEditingController();
  bool _isLoggingWeight = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightInputController.dispose();
    _noteInputController.dispose();
    super.dispose();
  }

  void _showLogWeightDialog(BuildContext context, ProgressNotifier notifier) {
    _weightInputController.clear();
    _noteInputController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Log Weight",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _weightInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Current Weight (kg)",
                  hintText: "E.g. 74.5",
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteInputController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Optional Note",
                  hintText: "Morning weight, after workout...",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.outfit(color: AppColors.darkTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(_weightInputController.text);
                if (weight != null && weight > 0) {
                  Navigator.pop(context);
                  final success = await notifier.logWeight(
                    weightKg: weight,
                    note: _noteInputController.text.trim(),
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text(
                          "Logged weight of $weight kg successfully!",
                          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                    // Show rewarded video ad once per day after weight is saved
                    AdService.showRewardedOncePerDay('weight_trend');
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Progress & Analytics",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.darkTextSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Weight"),
            Tab(text: "Energy"),
            Tab(text: "Macros"),
            Tab(text: "Streaks"),
          ],
        ),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildWeightTab(context, state, notifier),
                  _buildEnergyTab(state),
                  _buildMacrosTab(state),
                  _buildStreaksTab(state),
                ],
              ),
      ),
    );
  }

  // --- WEIGHT TAB ---

  Widget _buildWeightTab(BuildContext context, ProgressState state, ProgressNotifier notifier) {
    final hasWeight = state.weightTimeline.isNotEmpty;
    final List<double> weightPoints = state.weightTimeline.map((w) => w.weightKg).toList();
    final double currentWeight = hasWeight ? state.weightTimeline.last.weightKg : 0.0;
    
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => notifier.fetchProgressData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current weight indicator card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Weight",
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
                    ),
                    Text(
                      hasWeight ? "$currentWeight kg" : "-- kg",
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showLogWeightDialog(context, notifier),
                  icon: const Icon(LucideIcons.plus, size: 16, color: Colors.black),
                  label: Text("Log Weight", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Canvas Line Chart Card
            Container(
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: hasWeight && weightPoints.length > 1
                  ? CustomPaint(
                      painter: _SparklinePainter(
                        values: weightPoints,
                        lineColor: AppColors.primary,
                        glowColor: AppColors.primary,
                      ),
                    )
                  : Center(
                      child: Text(
                        "Not enough weight data to draw chart",
                        style: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Period selector (7d vs 30d)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Timeline History",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    _buildPeriodChip(7, state, notifier),
                    const SizedBox(width: 8),
                    _buildPeriodChip(30, state, notifier),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of weight history items
            if (!hasWeight)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("No weight logs recorded yet.", style: GoogleFonts.outfit(color: AppColors.darkTextSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.weightTimeline.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.darkBorder, height: 1),
                itemBuilder: (context, index) {
                  // Display newest logs first
                  final entry = state.weightTimeline[state.weightTimeline.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(entry.date),
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Moving Avg: ${entry.movingAverage7d.toStringAsFixed(1)} kg",
                              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          "${entry.weightKg} kg",
                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(int days, ProgressState state, ProgressNotifier notifier) {
    final isSelected = state.selectedPeriodDays == days;
    return ChoiceChip(
      selected: isSelected,
      label: Text("$days Days", style: GoogleFonts.outfit(fontSize: 12)),
      onSelected: (_) => notifier.fetchProgressData(periodDays: days),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.darkSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // --- ENERGY TAB ---

  Widget _buildEnergyTab(ProgressState state) {
    final hasData = state.caloriesTimeline.isNotEmpty;
    final consumedPoints = state.caloriesTimeline.map((c) => c.caloriesConsumed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calorie Intake Trends",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            "Track daily caloric budget against your set targets.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Calorie Line Chart Card
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: hasData && consumedPoints.length > 1
                ? CustomPaint(
                    painter: _SparklinePainter(
                      values: consumedPoints,
                      lineColor: AppColors.secondary,
                      glowColor: AppColors.secondary,
                    ),
                  )
                : Center(
                    child: Text(
                      "Not enough calorie data to draw chart",
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          // Average Calories readouts
          Text(
            "Daily Highlights",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          _buildHighlightRow(
            "Average Intake",
            hasData
                ? "${(consumedPoints.reduce((a, b) => a + b) / consumedPoints.length).round()} kcal"
                : "-- kcal",
            AppColors.secondary,
          ),
          const Divider(color: AppColors.darkBorder),
          _buildHighlightRow(
            "Average Burned",
            hasData
                ? "${(state.caloriesTimeline.map((c) => c.caloriesBurned).reduce((a, b) => a + b) / consumedPoints.length).round()} kcal"
                : "-- kcal",
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  // --- MACROS TAB ---

  Widget _buildMacrosTab(ProgressState state) {
    final hasData = state.macrosTimeline.isNotEmpty;
    final carbsPoints = state.macrosTimeline.map((m) => m.carbsG).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Macronutrient Balances",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            "Monitor carbohydrate portions logged daily.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Carbs Chart
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: hasData && carbsPoints.length > 1
                ? CustomPaint(
                    painter: _SparklinePainter(
                      values: carbsPoints,
                      lineColor: AppColors.secondary,
                      glowColor: AppColors.secondary,
                    ),
                  )
                : Center(
                    child: Text(
                      "Not enough macronutrient data",
                      style: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          // Average protein / carbs / fats distribution
          Text(
            "Average Intake Breakdown",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          _buildMacroSummaryItem("Carbohydrates", AppColors.secondary),
          const SizedBox(height: 12),
          _buildMacroSummaryItem("Protein", AppColors.primary),
          const SizedBox(height: 12),
          _buildMacroSummaryItem("Fats", AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildMacroSummaryItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }

  // --- STREAKS TAB ---

  Widget _buildStreaksTab(ProgressState state) {
    final streak = state.streak;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large burning streak flame icon
          Icon(
            LucideIcons.flame,
            size: 100,
            color: streak != null && streak.currentStreak > 0 ? AppColors.accent : AppColors.darkBorder,
          ),
          const SizedBox(height: 24),
          
          Text(
            streak != null ? "${streak.currentStreak} Day Streak!" : "0 Day Streak!",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36),
          ),
          const SizedBox(height: 8),
          
          Text(
            "Consistency is key. Log foods daily to maintain your logging streak.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Streak stats cards
          Row(
            children: [
              Expanded(
                child: _buildStreakStatCard(
                  "Current Streak",
                  streak != null ? "${streak.currentStreak} days" : "0 days",
                  LucideIcons.calendarCheck,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakStatCard(
                  "Longest Streak",
                  streak != null ? "${streak.longestStreak} days" : "0 days",
                  LucideIcons.trophy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
          Text(
            value,
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// --- CURVED SPARKLINE CHART PAINTER ---

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color glowColor;

  _SparklinePainter({required this.values, required this.lineColor, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double minVal = values.first;
    double maxVal = values.first;
    for (final v in values) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    
    if (minVal == maxVal) {
      minVal -= 1.0;
      maxVal += 1.0;
    }
    final range = maxVal - minVal;

    final width = size.width;
    final height = size.height;
    final pointsCount = values.length;
    final stepX = width / (pointsCount - 1);

    final offsets = <Offset>[];
    for (int i = 0; i < pointsCount; i++) {
      final x = i * stepX;
      final normY = (values[i] - minVal) / range;
      final y = height - (normY * height * 0.7) - (height * 0.15);
      offsets.add(Offset(x, y));
    }

    // 1. Draw area gradient path (glow under curve)
    final glowPath = Path()..moveTo(0, height);
    for (final p in offsets) {
      glowPath.lineTo(p.dx, p.dy);
    }
    glowPath.lineTo(width, height);
    glowPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [glowColor.withOpacity(0.2), glowColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(glowPath, fillPaint);

    // 2. Draw smooth bezier curve line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final curvePath = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    for (int i = 0; i < pointsCount - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final controlPoint1 = Offset(p1.dx + stepX / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - stepX / 2, p2.dy);
      curvePath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }
    canvas.drawPath(curvePath, linePaint);

    // 3. Draw dots on data points
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final p in offsets) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 2.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
