import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/ai/providers/ai_coach_provider.dart';

class AiDebriefPage extends ConsumerStatefulWidget {
  const AiDebriefPage({super.key});

  @override
  ConsumerState<AiDebriefPage> createState() => _AiDebriefPageState();
}

class _AiDebriefPageState extends ConsumerState<AiDebriefPage> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _committedTweaks = {};

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _committedTweaks.clear(); // Reset checkbox commitments for new date
    });
  }

  @override
  Widget build(BuildContext context) {
    final debriefFuture = ref.watch(aiDebriefProvider(_dateStr));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Nutrition Debrief",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Selector Bar
            _buildDateSelector(),

            // Content Body
            Expanded(
              child: debriefFuture.when(
                data: (debrief) => _buildDebriefContent(debrief),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                error: (err, stack) => _buildErrorState(err),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => _changeDate(-1),
          ),
          Row(
            children: [
              const Icon(LucideIcons.calendar, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM d').format(_selectedDate),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
            // Don't allow selecting future dates
            onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)))
                ? () => _changeDate(1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDebriefContent(DailyDebrief debrief) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Quote Box
          Text(
            "Coach Summary",
            style: GoogleFonts.outfit(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.quote,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    debrief.summary,
                    style: GoogleFonts.outfit(
                      color: AppColors.darkTextPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nutritional Deficits Flags
          Text(
            "Nutritional Deficits Flagged",
            style: GoogleFonts.outfit(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...debrief.deficits.map((deficit) => _buildDeficitItem(deficit)),
          const SizedBox(height: 24),

          // Actionable Tweaks for Tomorrow
          Text(
            "Tweaks for Tomorrow",
            style: GoogleFonts.outfit(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Commit to these changes to keep moving closer to your targets:",
            style: GoogleFonts.outfit(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (debrief.tweaks.isEmpty)
            Text(
              "No suggestions. Great job keeping your targets!",
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
            )
          else
            ...debrief.tweaks.map((tweak) => _buildTweakCheckbox(tweak)),
        ],
      ),
    );
  }

  Widget _buildDeficitItem(String text) {
    final isNone = text.toLowerCase().contains("none");
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isNone ? AppColors.primary.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNone ? AppColors.primary.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNone ? LucideIcons.circleCheck : LucideIcons.alertTriangle,
            color: isNone ? AppColors.primary : AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTweakCheckbox(String tweak) {
    final isChecked = _committedTweaks[tweak] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? AppColors.primary.withOpacity(0.4) : AppColors.darkBorder.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          tweak,
          style: GoogleFonts.outfit(
            color: isChecked ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
            fontSize: 13,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        value: isChecked,
        activeColor: AppColors.primary,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (val) {
          setState(() {
            _committedTweaks[tweak] = val ?? false;
          });
        },
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              "Could not analyze nutrition logs",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              err.toString().contains("404")
                  ? "Ensure you have logged some food items for this date."
                  : "Please check your network and make sure the server is online.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text("Retry"),
              onPressed: () {
                ref.invalidate(aiDebriefProvider(_dateStr));
              },
            )
          ],
        ),
      ),
    );
  }
}
