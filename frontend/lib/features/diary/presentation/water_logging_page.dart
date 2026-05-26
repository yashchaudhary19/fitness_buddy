import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/providers/summary_provider.dart';

class WaterLoggingPage extends ConsumerStatefulWidget {
  const WaterLoggingPage({super.key});

  @override
  ConsumerState<WaterLoggingPage> createState() => _WaterLoggingPageState();
}

class _WaterLoggingPageState extends ConsumerState<WaterLoggingPage> with TickerProviderStateMixin {
  late AnimationController _waveHorizontalController;
  late AnimationController _levelController;
  late Animation<double> _levelAnimation;

  double _currentPercent = 0.0;
  double _targetPercent = 0.0;
  double _waterConsumed = 0.0;
  double _waterGoal = 2000.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Wave horizontal movement
    _waveHorizontalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Wave vertical fill animation
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _levelAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.easeOutCubic),
    );

    // Load initial values from summary provider after frame binding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final summary = ref.read(summaryProvider).summary;
      if (summary != null) {
        setState(() {
          _waterConsumed = summary.waterConsumedMl;
          _waterGoal = summary.waterGoalMl;
          _currentPercent = (_waterConsumed / _waterGoal).clamp(0.0, 1.0);
          _targetPercent = _currentPercent;
          
          _levelAnimation = Tween<double>(begin: 0.0, end: _currentPercent).animate(
            CurvedAnimation(parent: _levelController, curve: Curves.easeOutCubic),
          );
          _levelController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _waveHorizontalController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _addWater(int amountMl) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Optimistically update vertical level animation
    final double prevPercent = _currentPercent;
    _waterConsumed += amountMl;
    _currentPercent = (_waterConsumed / _waterGoal).clamp(0.0, 1.0);

    _levelAnimation = Tween<double>(begin: prevPercent, end: _currentPercent).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.easeOutCubic),
    );
    _levelController.forward(from: 0.0);

    try {
      final notifier = ref.read(summaryProvider.notifier);
      await notifier.addWaterQuick(amountMl);
    } catch (_) {}

    setState(() {
      _isSaving = false;
    });
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
          "Water Tracker",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Centered Animated Wave Jar Container
            Expanded(
              child: Center(
                child: Container(
                  width: 250,
                  height: 380,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.darkBorder, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Stack(
                      children: [
                        // Shifting fluid waves custom paint
                        AnimatedBuilder(
                          animation: Listenable.merge([_waveHorizontalController, _levelController]),
                          builder: (context, child) {
                            return Positioned.fill(
                              child: CustomPaint(
                                painter: _WavePainter(
                                  fillProgress: _levelAnimation.value,
                                  animationValue: _waveHorizontalController.value,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Centered consumption readout overlay
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${_waterConsumed.round()}",
                                style: GoogleFonts.outfit(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "of ${_waterGoal.round()} ml",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${(_currentPercent * 100).round()}% Hydrated",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Quick add portion log buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  _buildIncrementButton("Cups", "+250", 250, LucideIcons.glassWater),
                  const SizedBox(width: 12),
                  _buildIncrementButton("Bottle", "+500", 500, LucideIcons.cupSoda),
                  const SizedBox(width: 12),
                  _buildIncrementButton("Large", "+750", 750, LucideIcons.droplet),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIncrementButton(String label, String action, int amount, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: _isSaving ? null : () => _addWater(amount),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 24),
              const SizedBox(height: 8),
              Text(
                action,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WAVE CUSTOM PAINTER ---

class _WavePainter extends CustomPainter {
  final double fillProgress;
  final double animationValue;

  _WavePainter({required this.fillProgress, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double levelY = size.height - (size.height * fillProgress);

    // If progress is empty, don't draw anything
    if (fillProgress <= 0.0) return;

    // Draw deep background wave layer
    final paint1 = Paint()
      ..color = Colors.blueAccent.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    
    final path1 = Path();
    path1.moveTo(0, levelY);
    for (double i = 0; i <= size.width; i++) {
      final double waveX = (i / size.width) * 2 * math.pi;
      final double waveY = levelY + 12 * math.sin(waveX + (animationValue * 2 * math.pi));
      path1.lineTo(i, waveY);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Draw foreground wave layer
    final paint2 = Paint()
      ..color = Colors.blueAccent.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    
    final path2 = Path();
    path2.moveTo(0, levelY);
    for (double i = 0; i <= size.width; i++) {
      final double waveX = (i / size.width) * 2 * math.pi;
      // Inverse shift phase for dynamic crossing wave motion
      final double waveY = levelY + 8 * math.cos(waveX - (animationValue * 2 * math.pi));
      path2.lineTo(i, waveY);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.animationValue != animationValue;
  }
}
