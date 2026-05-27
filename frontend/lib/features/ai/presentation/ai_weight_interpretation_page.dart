import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/ads/ad_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/ai/providers/ai_coach_provider.dart';

class AiWeightInterpretationPage extends ConsumerStatefulWidget {
  const AiWeightInterpretationPage({super.key});

  @override
  ConsumerState<AiWeightInterpretationPage> createState() => _AiWeightInterpretationPageState();
}

class _AiWeightInterpretationPageState extends ConsumerState<AiWeightInterpretationPage> {
  bool _adShown = false;

  @override
  Widget build(BuildContext context) {
    final interpretationFuture = ref.watch(aiWeightInterpretationProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Weight Trend Analysis",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, size: 20, color: AppColors.darkTextSecondary),
            onPressed: () {
              ref.invalidate(aiWeightInterpretationProvider);
            },
            tooltip: "Recalculate Analysis",
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: interpretationFuture.when(
          data: (data) {
            if (!_adShown) {
              _adShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AdService.showRewardedOncePerDay('weight_trend');
              });
            }
            return _buildContent(context, ref, data);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          error: (err, stack) => _buildErrorState(context, ref, err),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WeightInterpretation data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Large Visual Target Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            ),
            child: const Icon(
              LucideIcons.lineChart,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            "Weekly Regression Trend",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "AI-generated analysis of your logged weights",
            style: GoogleFonts.outfit(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // Analysis Section
          _buildAnalysisCard(
            title: "Trend Explanation",
            content: data.interpretation,
            icon: LucideIcons.bot,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Suggestion Section
          _buildAnalysisCard(
            title: "Coaching Suggestions",
            content: data.suggestion,
            icon: LucideIcons.sparkles,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 32),
          
          Text(
            "Note: Weight trends are calculated using linear regression on your logging entries. Keep logging weights consistently for maximum accuracy.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppColors.darkTextSecondary.withOpacity(0.6),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.darkBorder, height: 24, thickness: 1),
            Text(
              content,
              style: GoogleFonts.outfit(
                color: AppColors.darkTextPrimary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              "Could not analyze weight trend",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              "Ensure you have set weight goals in your profile and logged weight entries.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text("Retry"),
              onPressed: () {
                ref.invalidate(aiWeightInterpretationProvider);
              },
            )
          ],
        ),
      ),
    );
  }
}
