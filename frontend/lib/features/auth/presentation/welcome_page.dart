import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  final List<String> _titles = [
    "Ready for some wins?\nStart tracking, it's easy!",
    "Discover the impact of\nyour food and fitness",
    "And make mindful eating\na habit for life",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Welcome to nutritrack
            Text(
              "Welcome to",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "nutrivault",
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: const Color(0xFF3B82F6), // Brand blue matching MyFitnessPal theme style
              ),
            ),
            const SizedBox(height: 24),

            // Onboarding Carousel Card
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentSlide = index;
                  });
                },
                children: [
                  _buildSlideOne(),
                  _buildSlideTwo(),
                  _buildSlideThree(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Subtitle Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey<int>(_currentSlide),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                height: 70,
                child: Text(
                  _titles[_currentSlide],
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _currentSlide;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF1E294B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Sign Up For Free Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Sign Up For Free",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Log In Text Button
                  TextButton(
                    onPressed: () => context.push('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text(
                      "Log In",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer Version Info
            Text(
              "Version 1.0.0",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.darkTextSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- CAROUSEL SLIDES BUILDERS ---

  Widget _buildSlideOne() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              "assets/images/runner_onboarding.png",
              fit: BoxFit.cover,
            ),
            // Bottom Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Glassmorphic Protein Chart overlay
            Positioned(
              left: 20,
              bottom: 30,
              child: _buildGlassmorphicContainer(
                width: 190,
                height: 140,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Protein",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Last 7 days",
                            style: GoogleFonts.outfit(
                              color: AppColors.darkTextSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const Expanded(child: SizedBox()),
                      // Mini Custom Bar Chart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMiniBar("M", 25),
                          _buildMiniBar("T", 45),
                          _buildMiniBar("W", 50),
                          _buildMiniBar("T", 40),
                          _buildMiniBar("F", 65),
                          _buildMiniBar("S", 55),
                          _buildMiniBar("S", 75),
                        ],
                      ),
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

  Widget _buildSlideTwo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1E294B), // Premium dark container
          border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Device Frame Mockup
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Phone screen background
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mini App Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: const NetworkImage(
                                      "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100",
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "nutrivault",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),
                                      Text(
                                        "PREMIUM 👑",
                                        style: GoogleFonts.outfit(
                                          fontSize: 6,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                LucideIcons.bell,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Today Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Edit",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Calories card
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Calories",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "Remaining = Goal - Food + Exercise",
                                  style: GoogleFonts.outfit(
                                    fontSize: 6,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Progress Ring
                                    SizedBox(
                                      width: 54,
                                      height: 54,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            value: 0.65,
                                            strokeWidth: 5,
                                            backgroundColor: Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "1,250",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                "Remaining",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 5,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Calorie values list
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildMiniValueRow(LucideIcons.flag, "Base Goal", "1,500"),
                                        const SizedBox(height: 3),
                                        _buildMiniValueRow(LucideIcons.soup, "Food", "650", color: Colors.blue),
                                        const SizedBox(height: 3),
                                        _buildMiniValueRow(LucideIcons.flame, "Exercise", "400", color: Colors.orange),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Steps and Exercise row
                          Expanded(
                            child: Row(
                              children: [
                                // Steps Card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Steps",
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.footprints, size: 10, color: Colors.pink),
                                            const SizedBox(width: 3),
                                            Text(
                                              "6,342",
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "Goal: 15,000",
                                          style: GoogleFonts.outfit(
                                            fontSize: 6,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: const LinearProgressIndicator(
                                            value: 0.42,
                                            minHeight: 3,
                                            backgroundColor: Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Exercise Card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Exercise",
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.flame, size: 10, color: Colors.orange),
                                            const SizedBox(width: 3),
                                            Text(
                                              "400 cal",
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.clock, size: 10, color: Colors.amber),
                                            const SizedBox(width: 3),
                                            Text(
                                              "0:23 hr",
                                              style: GoogleFonts.outfit(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideThree() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              "assets/images/salad_onboarding.png",
              fit: BoxFit.cover,
            ),
            // Bottom Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Glassmorphic Macros Ring list overlay
            Positioned(
              left: 20,
              bottom: 30,
              child: _buildGlassmorphicContainer(
                width: 110,
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroProgressColumn("Protein", "32", 0.32, Colors.orange),
                      _buildMacroProgressColumn("Fat", "20", 0.20, Colors.purpleAccent),
                      _buildMacroProgressColumn("Carbs", "57", 0.57, Colors.cyan),
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

  // --- COMPONENT HELPERS ---

  Widget _buildGlassmorphicContainer({
    required double width,
    required double height,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMiniBar(String day, int percentage) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 12,
            height: (60 * (percentage / 100)),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniValueRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          "$label ",
          style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildMacroProgressColumn(
    String name,
    String value,
    double percent,
    Color progressColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent,
                strokeWidth: 3,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 7,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
