import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/network/connectivity_provider.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_summary_page.dart';
import 'package:frontend/features/diary/presentation/diary_page.dart';
import 'package:frontend/features/progress/presentation/progress_page.dart';
import 'package:frontend/features/ai/presentation/ai_coaching_page.dart';
import 'package:frontend/features/profile/presentation/profile_page.dart';

class DashboardFrame extends ConsumerStatefulWidget {
  const DashboardFrame({super.key});

  @override
  ConsumerState<DashboardFrame> createState() => _DashboardFrameState();
}

class _DashboardFrameState extends ConsumerState<DashboardFrame> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardSummaryPage(),
    const DiaryPage(),
    const ProgressPage(),
    const AiCoachingPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Screen Page Body (leaving bottom spacing for floating nav bar)
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),

          // Offline Warning Banner
          if (!connectivity.isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.wifiOff, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Offline Mode - Disconnected from server",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Glassmorphic Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.darkBorder.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, LucideIcons.home, "Summary"),
                      _buildNavItem(1, LucideIcons.calendar, "Diary"),
                      _buildNavItem(2, LucideIcons.lineChart, "Progress"),
                      _buildNavItem(3, LucideIcons.sparkles, "AI Coach"),
                      _buildNavItem(4, LucideIcons.user, "Profile"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glowing effect when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // Text label
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
