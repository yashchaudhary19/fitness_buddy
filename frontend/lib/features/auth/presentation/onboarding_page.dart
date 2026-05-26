import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isSubmitting = false;

  // Selected values
  String _goalType = 'lose'; // lose, maintain, gain
  String _gender = 'male'; // male, female
  int _age = 25;
  double _heightCm = 175.0;
  double _currentWeightKg = 75.0;
  double _targetWeightKg = 70.0;
  String _activityLevel = 'moderate'; // sedentary, light, moderate, active, very_active
  double _weeklyPaceKg = 0.5;

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit onboarding goals!
      setState(() => _isSubmitting = true);
      try {
        await ref.read(authProvider.notifier).submitOnboarding(
          goalType: _goalType,
          currentWeight: _currentWeightKg,
          targetWeight: _targetWeightKg,
          height: _heightCm,
          age: _age,
          gender: _gender,
          activityLevel: _activityLevel,
          weeklyPace: _weeklyPaceKg,
        );
      } catch (e) {
        setState(() => _isSubmitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              e.toString().replaceAll("ApiException: ", ""),
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          "Step ${_currentStep + 1} of $_totalSteps",
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.darkTextSecondary),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  color: AppColors.primary,
                  backgroundColor: AppColors.darkSurface,
                  minHeight: 6,
                ),
              ),
            ),
            
            // Step contents scroll view
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildGoalStep(),
                  _buildBioStep(),
                  _buildMetricsStep(),
                  _buildActivityStep(),
                  _buildSummaryStep(),
                ],
              ),
            ),

            // Navigation Button Frame
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          _currentStep == _totalSteps - 1 ? "Calculate & Begin" : "Continue",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- QUESTIONNAIRE STEP BUILDERS ---

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "What is your primary goal?",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "This helps us calculate your daily caloric needs and macronutrient thresholds.",
            style: GoogleFonts.outfit(fontSize: 16, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 32),
          
          _buildSelectionCard(
            title: "Lose Weight",
            subtitle: "Burn fat, build lean muscle, and feel healthier.",
            value: 'lose',
            selectedValue: _goalType,
            icon: LucideIcons.trendingDown,
            onTap: () => setState(() => _goalType = 'lose'),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: "Maintain Weight",
            subtitle: "Optimize energy levels, recovery, and core strength.",
            value: 'maintain',
            selectedValue: _goalType,
            icon: LucideIcons.checkCircle,
            onTap: () => setState(() => _goalType = 'maintain'),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: "Gain Weight",
            subtitle: "Build size, increase muscle mass, and gain strength.",
            value: 'gain',
            selectedValue: _goalType,
            icon: LucideIcons.trendingUp,
            onTap: () => setState(() => _goalType = 'gain'),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Tell us about yourself",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "We use gender and age to compute your basal metabolic rate (BMR).",
            style: GoogleFonts.outfit(fontSize: 16, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 32),
          
          Text(
            "Biological Gender",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton(
                  title: "Male",
                  value: 'male',
                  selectedValue: _gender,
                  icon: LucideIcons.user,
                  onTap: () => setState(() => _gender = 'male'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderButton(
                  title: "Female",
                  value: 'female',
                  selectedValue: _gender,
                  icon: LucideIcons.user,
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Age",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "$_age years old",
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _age.toDouble(),
            min: 15,
            max: 80,
            divisions: 65,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.darkSurface,
            onChanged: (val) {
              setState(() {
                _age = val.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Enter physical metrics",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          
          // Height display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Height",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${_heightCm.round()} cm",
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Slider(
            value: _heightCm,
            min: 120,
            max: 220,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.darkSurface,
            onChanged: (val) => setState(() => _heightCm = val),
          ),
          const SizedBox(height: 32),
          
          // Current weight display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Current Weight",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${_currentWeightKg.toStringAsFixed(1)} kg",
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Slider(
            value: _currentWeightKg,
            min: 40,
            max: 150,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.darkSurface,
            onChanged: (val) {
              setState(() {
                _currentWeightKg = val;
                // Keep target weight in sync bounds
                if (_goalType == 'lose' && _targetWeightKg > _currentWeightKg) {
                  _targetWeightKg = _currentWeightKg - 2;
                } else if (_goalType == 'gain' && _targetWeightKg < _currentWeightKg) {
                  _targetWeightKg = _currentWeightKg + 2;
                } else if (_goalType == 'maintain') {
                  _targetWeightKg = _currentWeightKg;
                }
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Target weight display (if not maintaining)
          if (_goalType != 'maintain') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target Weight",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${_targetWeightKg.toStringAsFixed(1)} kg",
                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Slider(
              value: _targetWeightKg,
              min: 40,
              max: 150,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.darkSurface,
              onChanged: (val) {
                // Bounds enforcement
                if (_goalType == 'lose' && val >= _currentWeightKg) return;
                if (_goalType == 'gain' && val <= _currentWeightKg) return;
                setState(() => _targetWeightKg = val);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "What is your activity level?",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          
          _buildActivityCard("Sedentary", "Little to no exercise, desk job", "sedentary"),
          const SizedBox(height: 12),
          _buildActivityCard("Lightly Active", "1-3 days/week light exercise", "light"),
          const SizedBox(height: 12),
          _buildActivityCard("Moderately Active", "3-5 days/week moderate workout", "moderate"),
          const SizedBox(height: 12),
          _buildActivityCard("Very Active", "6-7 days/week intense exercise", "active"),
          const SizedBox(height: 12),
          _buildActivityCard("Extra Active", "Professional athlete / physical labor", "very_active"),
          
          if (_goalType != 'maintain') ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Weekly Pace",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${_weeklyPaceKg.toStringAsFixed(2)} kg / week",
                  style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [0.25, 0.50, 0.75, 1.0].map((pace) {
                final isSelected = _weeklyPaceKg == pace;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text("${pace.toStringAsFixed(2)}"),
                      onSelected: (_) => setState(() => _weeklyPaceKg = pace),
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
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Review your profile",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Our engine will compute your macros based on these details.",
            style: GoogleFonts.outfit(fontSize: 16, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                _buildSummaryRow("Primary Goal", _goalType.toUpperCase()),
                const Divider(color: AppColors.darkBorder),
                _buildSummaryRow("Gender", _gender.toUpperCase()),
                const Divider(color: AppColors.darkBorder),
                _buildSummaryRow("Age", "$_age years old"),
                const Divider(color: AppColors.darkBorder),
                _buildSummaryRow("Height", "${_heightCm.round()} cm"),
                const Divider(color: AppColors.darkBorder),
                _buildSummaryRow("Weight", "${_currentWeightKg.toStringAsFixed(1)} kg"),
                if (_goalType != 'maintain') ...[
                  const Divider(color: AppColors.darkBorder),
                  _buildSummaryRow("Target Weight", "${_targetWeightKg.toStringAsFixed(1)} kg"),
                  const Divider(color: AppColors.darkBorder),
                  _buildSummaryRow("Weekly Pace", "${_weeklyPaceKg} kg/week"),
                ],
                const Divider(color: AppColors.darkBorder),
                _buildSummaryRow("Activity Level", _activityLevel.replaceAll("_", " ").toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required String value,
    required String selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: isSelected ? AppColors.primary : AppColors.darkTextSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppColors.darkTextSecondary,
                      fontSize: 14,
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

  Widget _buildGenderButton({
    required String title,
    required String value,
    required String selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.darkTextSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(String title, String desc, String code) {
    final isSelected = _activityLevel == code;
    return GestureDetector(
      onTap: () => setState(() => _activityLevel = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(LucideIcons.check, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 15)),
          Text(val, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
