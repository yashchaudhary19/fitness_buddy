import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/theme/app_theme.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Dark background matching screen
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Premium Header Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(text: "Stay on it with tools that\nturn "),
                    TextSpan(
                      text: "habits into results.",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFCD34D), // Golden yellow
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Visual Strawberry Rocket Illustration
              Center(
                child: SizedBox(
                  width: 200,
                  height: 220,
                  child: CustomPaint(
                    painter: _StrawberryRocketPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Features List
              _buildFeatureItem(
                icon: LucideIcons.scanBarcode,
                title: "Scan a barcode",
                subtitle: "to log lightning fast",
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: LucideIcons.mic,
                title: "Use your voice",
                subtitle: "to log just by saying it",
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: LucideIcons.camera,
                title: "Take a photo",
                subtitle: "to log your entire meal",
              ),
              const SizedBox(height: 48),

              // Try Them For Free Button (Gradient)
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFBBF24), // Amber 300
                      Color(0xFFF59E0B), // Amber 500
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Simulate successful subscription upgrade
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Text(
                          "Welcome to Premium! All features unlocked.",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF0F172A), // Dark slate text
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    "Try them for free",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // No thanks Button
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8), // slate 400
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "No thanks",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icon Circular Container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151D30), // Dark background
              border: Border.all(
                color: const Color(0xFF2E3B5E).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFCD34D), // Golden color
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8), // gray-400
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a premium glowing strawberry rocket launching
class _StrawberryRocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw background glowing aura/stars
    final starsPaint = Paint()
      ..color = const Color(0xFFFCD34D).withOpacity(0.7)
      ..style = PaintingStyle.fill;
      
    // Draw minor stars
    canvas.drawCircle(Offset(center.dx + 60, center.dy - 60), 3, starsPaint);
    canvas.drawCircle(Offset(center.dx - 70, center.dy - 30), 2, starsPaint);
    canvas.drawCircle(Offset(center.dx - 40, center.dy - 80), 1.5, starsPaint);
    canvas.drawCircle(Offset(center.dx + 50, center.dy + 40), 2, starsPaint);

    // Draw background clouds (opaque navy/blue)
    final cloudPaint = Paint()
      ..color = const Color(0xFF1E294B).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 80, center.dy + 30), width: 90, height: 40),
      cloudPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 80, center.dy + 50), width: 110, height: 45),
      cloudPaint,
    );

    // Draw Rocket Tail Flame (Booster) at the bottom left-ish center
    final boosterPath = Path();
    boosterPath.moveTo(center.dx - 25, center.dy + 45);
    boosterPath.quadraticBezierTo(center.dx - 35, center.dy + 65, center.dx - 25, center.dy + 85);
    boosterPath.quadraticBezierTo(center.dx - 5, center.dy + 75, center.dx + 10, center.dy + 55);
    boosterPath.close();

    final boosterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF3B82F6), // Blue
          Color(0xFF60A5FA), // Light Blue
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(center.dx - 35, center.dy + 45, 50, 40))
      ..style = PaintingStyle.fill;
    canvas.drawPath(boosterPath, boosterPaint);

    // Draw Strawberry Body (Main Rocket) tilted slightly
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFEF4444), // Red
          Color(0xFFF87171), // Light Red
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(center.dx - 45, center.dy - 50, 90, 100))
      ..style = PaintingStyle.fill;

    // Draw strawberry oval body
    canvas.save();
    canvas.translate(center.dx, center.dy + 5);
    canvas.rotate(-0.35); // tilt rocket
    
    final strawberryRect = Rect.fromCenter(center: const Offset(0, -10), width: 75, height: 95);
    canvas.drawOval(strawberryRect, bodyPaint);

    // Draw green leaves at the bottom-left of the tilted strawberry (acts as booster wings/sepal)
    final sepalPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald Green
      ..style = PaintingStyle.fill;
      
    final sepalPath = Path();
    sepalPath.moveTo(-35, 20);
    sepalPath.quadraticBezierTo(-30, 35, -15, 30);
    sepalPath.quadraticBezierTo(-5, 45, 10, 30);
    sepalPath.quadraticBezierTo(25, 35, 30, 15);
    sepalPath.quadraticBezierTo(10, 10, -35, 20);
    sepalPath.close();
    canvas.drawPath(sepalPath, sepalPaint);

    // Draw green leaves at the top-right of tilted strawberry (sepal tips)
    final leafPaint = Paint()
      ..color = const Color(0xFF34D399) // Mint Green
      ..style = PaintingStyle.fill;

    // Leaf 1
    final leaf1Path = Path();
    leaf1Path.moveTo(-5, -55);
    leaf1Path.quadraticBezierTo(-15, -70, 0, -80);
    leaf1Path.quadraticBezierTo(10, -70, -5, -55);
    leaf1Path.close();
    canvas.drawPath(leaf1Path, leafPaint);

    // Leaf 2
    final leaf2Path = Path();
    leaf2Path.moveTo(5, -53);
    leaf2Path.quadraticBezierTo(20, -65, 25, -50);
    leaf2Path.quadraticBezierTo(15, -45, 5, -53);
    leaf2Path.close();
    canvas.drawPath(leaf2Path, leafPaint);

    // Draw white seeds on strawberry
    final seedPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
      
    final seeds = [
      const Offset(-15, -25), const Offset(5, -30), const Offset(20, -15),
      const Offset(-20, -5), const Offset(0, -10), const Offset(15, 5),
      const Offset(-10, 10), const Offset(5, 15),
    ];
    for (var seed in seeds) {
      canvas.drawOval(Rect.fromCenter(center: seed, width: 4, height: 7), seedPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
