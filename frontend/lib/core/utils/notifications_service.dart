import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  bool _remindersEnabled = true;

  bool get remindersEnabled => _remindersEnabled;

  void toggleReminders(bool value) {
    _remindersEnabled = value;
  }

  // Simulate scheduling a notification alert
  void scheduleLoggingReminders(BuildContext context) {
    if (!_remindersEnabled) return;

    // Display a beautiful simulated overlay notification snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        content: Row(
          children: [
            const Icon(LucideIcons.bellRing, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NutriVault Reminder",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    "Time to log your lunch and drink a glass of water!",
                    style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final notificationsService = NotificationsService();
