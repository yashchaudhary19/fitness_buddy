import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  
  Timer? _resendTimer;
  int _timerSeconds = 0;

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() {
      _timerSeconds = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final rawMsg = error.toString().replaceAll("ApiException: ", "").trim();
    final lower = rawMsg.toLowerCase();

    // Preserve friendly user errors from backend
    if (lower.contains("account does not exist") || 
        lower.contains("please sign up first")) {
      return "Account does not exist. Please sign up first.";
    }
    if (lower.contains("account already exists") || 
        lower.contains("please log in instead")) {
      return "An account already exists with this email. Please log in instead.";
    }
    if (lower.contains("invalid or expired verification code")) {
      return "The verification code is invalid or has expired. Please try again.";
    }

    // Network & connection errors
    if (lower.contains("connection error") || 
        lower.contains("socketexception") || 
        lower.contains("cannot reach the server") ||
        lower.contains("failed host lookup") ||
        lower.contains("connection refused") ||
        lower.contains("timeout")) {
      return "Could not connect to the server. Please check your internet connection and try again.";
    }

    // Generic fallback for system/raw errors
    if (lower.contains("exception") || 
        lower.contains("error") || 
        lower.contains("http") || 
        lower.contains("status code") ||
        lower.contains("null") ||
        lower.contains("format") ||
        lower.contains("type")) {
      return "Something went wrong on our end. Please try again later.";
    }

    return rawMsg;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isRegister = GoRouterState.of(context).matchedLocation == '/register';

    try {
      await ref.read(authProvider.notifier).sendOtp(
        _emailController.text.trim(),
        flow: isRegister ? 'signup' : 'login',
      );
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _errorMessage = _getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = "Please enter the 6-digit code";
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyOtp(
        _emailController.text.trim(),
        code,
      );
    } catch (e) {
      setState(() {
        _errorMessage = _getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('UI: "Continue with Google" button clicked');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('UI: invoking signInWithGoogle on authProvider notifier');
      await ref.read(authProvider.notifier).signInWithGoogle();
      debugPrint('UI: signInWithGoogle future completed');
    } catch (e) {
      debugPrint('UI: Error caught in _signInWithGoogle: $e');
      setState(() {
        _errorMessage = _getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = GoRouterState.of(context).matchedLocation == '/register';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Lock / Shield Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _otpSent ? LucideIcons.shieldCheck : LucideIcons.lock,
                      color: const Color(0xFF3B82F6),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title and Subtitle
                Center(
                  child: Text(
                    _otpSent 
                        ? "Verify Your Email" 
                        : (isRegister ? "Create Your Account" : "Welcome Back"),
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _otpSent
                        ? "Enter the 6-digit code sent to\n${_emailController.text}"
                        : (isRegister 
                            ? "We'll send a registration code to your email" 
                            : "We'll send a one-time code to your email"),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Error Message Display
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.outfit(color: AppColors.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (!_otpSent) ...[
                  // Email Input field
                  Text(
                    "Email Address",
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      prefixIcon: Icon(LucideIcons.mail, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                      hintText: "Enter your email",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Send Code Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isRegister ? "Send Registration Code" : "Send Verification Code",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).dividerColor, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        backgroundColor: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: CustomPaint(
                              painter: _GoogleLogoPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Continue with Google",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Sign In / Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isRegister ? "Already have an account?" : "Don't have an account?",
                        style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (isRegister) {
                                  context.pushReplacement('/login');
                                } else {
                                  context.pushReplacement('/register');
                                }
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                        child: Text(
                          isRegister ? "Log In" : "Register",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // OTP Code Input field
                  Text(
                    "Verification Code",
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                    enabled: !_isLoading,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: InputDecoration(
                      prefixIcon: Icon(LucideIcons.shield, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70),
                      hintText: "000000",
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verify and Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isRegister ? "Register & Log In" : "Verify & Log In",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resend code / Change email row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: (_isLoading || _timerSeconds > 0) ? null : _sendOtp,
                        child: Text(
                          _timerSeconds > 0
                              ? "Resend Code in ${_timerSeconds}s"
                              : "Resend Code",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: (_timerSeconds > 0)
                                ? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                  _errorMessage = null;
                                });
                              },
                        child: Text(
                          "Change Email",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const sweepColors = [
      Color(0xFF4285F4), // blue
      Color(0xFFEA4335), // red
      Color(0xFFFBBC04), // yellow
      Color(0xFF34A853), // green
    ];
    const startAngles = [0.0, 1.5708, 3.1416, 4.7124];

    for (int i = 0; i < 4; i++) {
      paint.color = sweepColors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngles[i],
        1.5708,
        true,
        paint,
      );
    }

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'G',
        style: TextStyle(
          color: const Color(0xFF4285F4),
          fontSize: size.width * 0.55,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
