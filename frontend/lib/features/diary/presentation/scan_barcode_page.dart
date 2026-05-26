import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/diary/providers/search_provider.dart';

class ScanBarcodePage extends ConsumerStatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  ConsumerState<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends ConsumerState<ScanBarcodePage> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final TextEditingController _manualController = TextEditingController();
  bool _isSearching = false;
  bool _torchOn = false;
  bool _hasDetected = false;

  @override
  void dispose() {
    _cameraController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String code) async {
    if (code.isEmpty || _isSearching || _hasDetected) return;

    setState(() {
      _isSearching = true;
      _hasDetected = true;
    });
    await _cameraController.stop();

    final food = await ref.read(searchProvider.notifier).lookupBarcode(code);

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (food != null) {
      context.pop(food);
    } else {
      // Show error and allow re-scanning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            "Barcode '$code' not found on Open Food Facts.",
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Scan Again',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _hasDetected = false);
              _cameraController.start();
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleManualEntry() async {
    final code = _manualController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _handleBarcodeDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Scan Product Barcode",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
              color: _torchOn ? AppColors.primary : Colors.white,
            ),
            onPressed: () {
              _cameraController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Live Camera Feed ---
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _handleBarcodeDetected(barcode!.rawValue!);
              }
            },
          ),

          // --- Scan Viewfinder overlay ---
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                Row(
                  children: [
                    Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
                    // Transparent scan window
                    Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(painter: _CornerPainter()),
                    ),
                    Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
                  ],
                ),
                Expanded(
                  flex: 3,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          // --- Scanning hint ---
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isSearching ? "Looking up barcode..." : "Align barcode within frame",
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // --- Loading indicator ---
          if (_isSearching)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          // --- Manual Entry card at the bottom ---
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Or enter barcode manually",
                    style: GoogleFonts.outfit(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _handleManualEntry(),
                          decoration: const InputDecoration(
                            hintText: "e.g. 5449000000996",
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _handleManualEntry,
                          child: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.arrowRight, color: Colors.black),
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
    );
  }
}

// Corner bracket painter for the scan viewfinder
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const length = 24.0;
    const r = 4.0;

    // Top-left
    canvas.drawPath(Path()..moveTo(0, length)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))..lineTo(length, 0), paint);
    // Top-right
    canvas.drawPath(Path()..moveTo(size.width - length, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))..lineTo(size.width, length), paint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(0, size.height - length)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))..lineTo(length, size.height), paint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(size.width - length, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r))..lineTo(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
