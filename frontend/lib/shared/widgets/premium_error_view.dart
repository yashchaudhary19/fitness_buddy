import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/theme/app_theme.dart';

class PremiumErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final String? title;
  final String? userFriendlyMessage;

  const PremiumErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.title,
    this.userFriendlyMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine friendly title & description based on raw error string if not provided explicitly
    String displayTitle = title ?? "Unable to sync data";
    String displayMessage = userFriendlyMessage ?? 
        "We are having trouble communicating with our servers. Please check your connection and try again.";
    
    final lowerError = errorMessage.toLowerCase();
    
    if (userFriendlyMessage == null) {
      if (lowerError.contains("connection failed") || 
          lowerError.contains("socketexception") || 
          lowerError.contains("cannot reach the server") ||
          lowerError.contains("connection timed out")) {
        displayTitle = title ?? "Connection lost";
        displayMessage = "Please verify your internet connection and tap retry below.";
      } else if (lowerError.contains("maintenance") || 
                 lowerError.contains("503") || 
                 lowerError.contains("502") || 
                 lowerError.contains("bad gateway")) {
        displayTitle = title ?? "Server is busy";
        displayMessage = "Our server is experiencing heavy traffic or temporary maintenance. Please try again in a few moments.";
      } else if (lowerError.contains("not found") || lowerError.contains("404")) {
        displayTitle = title ?? "Resource not found";
        displayMessage = "We couldn't locate the requested information. Try reloading or switching screens.";
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled warning icon container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.cloudLightning,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            
            // Styled Title
            Text(
              displayTitle,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            // Styled Description
            Text(
              displayMessage,
              style: GoogleFonts.outfit(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            
            // Retry Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Premium emerald green retry button matching screenshot style
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: Text(
                  "Retry",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
