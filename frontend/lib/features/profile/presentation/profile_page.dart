import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';


import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Form states
  bool _initialized = false;
  String? _goalType;
  double? _currentWeight;
  double? _targetWeight;
  double? _height;
  int? _age;
  String? _gender;
  String? _activityLevel;
  double? _weeklyPace;

  bool _isSaving = false;

  void _initializeForm(UserGoal goal) {
    if (_initialized) return;
    _goalType = goal.goalType;
    _currentWeight = goal.currentWeightKg;
    _targetWeight = goal.targetWeightKg;
    _height = goal.heightCm;
    _age = goal.age;
    _gender = goal.gender;
    _activityLevel = goal.activityLevel;
    _weeklyPace = goal.weeklyPaceKg;
    _initialized = true;
  }

  Future<void> _submitForm(ProfileNotifier notifier) async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    
    final success = await notifier.updateGoalProfile(
      goalType: _goalType!,
      currentWeight: _currentWeight!,
      targetWeight: _targetWeight!,
      height: _height!,
      age: _age!,
      gender: _gender!,
      activityLevel: _activityLevel!,
      weeklyPace: _weeklyPace!,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            "Profile goals updated successfully!",
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    if (state.goal != null) {
      _initializeForm(state.goal!);
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "My Goal Profile",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: state.isLoading && state.goal == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.goal == null
                ? _buildErrorView(state.errorMessage ?? "No goal profile found.", notifier)
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Targets Display Card
                          _buildTargetsCard(state.goal!),
                          const SizedBox(height: 24),

                          Text(
                            "Goal Parameters",
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          // Goal Editing Fields List
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Column(
                              children: [
                                // Goal type dropdown
                                _buildDropdownRow(
                                  label: "Fitness Goal",
                                  value: _goalType,
                                  items: const [
                                    DropdownMenuItem(value: 'lose', child: Text("Weight Loss")),
                                    DropdownMenuItem(value: 'maintain', child: Text("Maintenance")),
                                    DropdownMenuItem(value: 'gain', child: Text("Muscle Gain")),
                                  ],
                                  onChanged: (val) => setState(() => _goalType = val!),
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                // Gender dropdown
                                _buildDropdownRow(
                                  label: "Gender",
                                  value: _gender,
                                  items: const [
                                    DropdownMenuItem(value: 'male', child: Text("Male")),
                                    DropdownMenuItem(value: 'female', child: Text("Female")),
                                    DropdownMenuItem(value: 'other', child: Text("Other")),
                                  ],
                                  onChanged: (val) => setState(() => _gender = val!),
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                // Activity level dropdown
                                _buildDropdownRow(
                                  label: "Activity Level",
                                  value: _activityLevel,
                                  items: const [
                                    DropdownMenuItem(value: 'sedentary', child: Text("Sedentary")),
                                    DropdownMenuItem(value: 'light', child: Text("Lightly Active")),
                                    DropdownMenuItem(value: 'moderate', child: Text("Moderately Active")),
                                    DropdownMenuItem(value: 'active', child: Text("Very Active")),
                                    DropdownMenuItem(value: 'very_active', child: Text("Extra Active")),
                                  ],
                                  onChanged: (val) => setState(() => _activityLevel = val!),
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                // Numeric values
                                _buildNumericFormRow(
                                  label: "Current Weight (kg)",
                                  initialValue: _currentWeight.toString(),
                                  onChanged: (val) => _currentWeight = double.tryParse(val) ?? _currentWeight,
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                _buildNumericFormRow(
                                  label: "Target Weight (kg)",
                                  initialValue: _targetWeight.toString(),
                                  onChanged: (val) => _targetWeight = double.tryParse(val) ?? _targetWeight,
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                _buildNumericFormRow(
                                  label: "Weight Pace (kg/wk)",
                                  initialValue: _weeklyPace.toString(),
                                  onChanged: (val) => _weeklyPace = double.tryParse(val) ?? _weeklyPace,
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                _buildNumericFormRow(
                                  label: "Height (cm)",
                                  initialValue: _height.toString(),
                                  onChanged: (val) => _height = double.tryParse(val) ?? _height,
                                ),
                                const Divider(color: AppColors.darkBorder, height: 24),

                                _buildNumericFormRow(
                                  label: "Age (years)",
                                  initialValue: _age.toString(),
                                  onChanged: (val) => _age = int.tryParse(val) ?? _age,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save and Update button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : () => _submitForm(notifier),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Text(
                                      "Save & Recalculate Goals",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Privacy Policy button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://nutrivault.techotd.in/privacy');
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.error,
                                          content: Text(
                                            "Could not launch Privacy Policy link.",
                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.error,
                                        content: Text(
                                          "Error opening Privacy Policy.",
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(LucideIcons.shield, size: 18),
                              label: Text(
                                "Privacy Policy",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Log Out button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () => notifier.logout(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(LucideIcons.logOut, size: 18),
                              label: Text(
                                "Log Out of NutriTrack",
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

  Widget _buildTargetsCard(UserGoal goal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Active Targets",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTargetMetricReadout("Budget Calories", "${goal.dailyCalorieTarget}", "kcal"),
              ),
              Container(width: 1, height: 40, color: AppColors.primary.withOpacity(0.3)),
              Expanded(
                child: _buildTargetMetricReadout("Daily Water", "${goal.dailyWaterMl}", "ml"),
              ),
            ],
          ),
          const Divider(color: AppColors.primary, height: 32, thickness: 0.2),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildTargetMacroReadout("Carbs", "${goal.dailyCarbsG}g", AppColors.secondary),
              _buildTargetMacroReadout("Protein", "${goal.dailyProteinG}g", AppColors.primary),
              _buildTargetMacroReadout("Fats", "${goal.dailyFatG}g", AppColors.accent),
              _buildTargetMacroReadout("Fiber", "${goal.dailyFiberG}g", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetMetricReadout(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 26),
        ),
        Text(
          "$label ($unit)",
          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTargetMacroReadout(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Safety: ensure value is actually in the items list to prevent crash
    final safeValue = items.any((item) => item.value == value) ? value : items.first.value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.darkSurface,
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
              iconEnabledColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericFormRow({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            initialValue: initialValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String error, ProfileNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => notifier.fetchGoalProfile(),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
