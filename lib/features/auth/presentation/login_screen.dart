import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Ambient glow effects
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Subtle grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Main content — full screen, no SafeArea clipping issues
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Top section: logo + text (flexible so it shrinks when keyboard opens)
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      MediaQuery.of(context).padding.top + 40,
                      32,
                      0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        _AnimatedLogo(),

                        const SizedBox(height: 36),

                        // App name
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFF9D97FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                          child: Text(
                            'Talkie',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 14),

                        // Tagline
                        Text(
                          'Hold. Talk. Connect.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B949E),
                            letterSpacing: 0.3,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 600.ms),

                        const SizedBox(height: 8),

                        // Sub tagline with pill badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeaturePill(
                              icon: Icons.bolt_rounded,
                              label: 'Instant',
                              color: const Color(0xFF6C63FF),
                            ),
                            const SizedBox(width: 8),
                            _FeaturePill(
                              icon: Icons.lock_rounded,
                              label: 'Secure',
                              color: const Color(0xFF00E5FF),
                            ),
                            const SizedBox(width: 8),
                            _FeaturePill(
                              icon: Icons.wifi_rounded,
                              label: 'Real-Time',
                              color: const Color(0xFF3FB950),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),

                // Bottom section: buttons (fixed height)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28,
                      0,
                      28,
                      MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isLoading)
                          const _LoadingView()
                        else ...[
                          // Google button
                          _GoogleSignInButton(
                            onPressed: () => _signInWithGoogle(context, ref),
                          )
                              .animate()
                              .fadeIn(delay: 800.ms, duration: 500.ms)
                              .slideY(begin: 0.4, end: 0),

                          const SizedBox(height: 16),

                          // Apple button
                          _AppleSignInButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF21262D),
                                  content: Text(
                                    'Apple Sign-In coming soon!',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(delay: 950.ms, duration: 500.ms)
                              .slideY(begin: 0.4, end: 0),

                          const SizedBox(height: 24),

                          // Footer
                          Text(
                            'By continuing, you agree to our Terms & Privacy Policy',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF484F58),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            content: Text(
              'Sign-in failed: ${e.toString()}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}

// ─── Animated Logo ─────────────────────────────────────────────────────────

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.55),
              blurRadius: 40,
              spreadRadius: 6,
            ),
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            'assets/talkie_icon.png',
            width: 118,
            height: 118,
            fit: BoxFit.cover,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.4, 0.4),
          curve: Curves.elasticOut,
          duration: 900.ms,
        );
  }
}

// ─── Feature Pill ──────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Sign In Button ─────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A42E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google G SVG-style icon
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4285F4),
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Apple Sign In Button ──────────────────────────────────────────────────

class _AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF30363D),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.apple_rounded,
                  size: 26,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Apple',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Signing you in...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF8B949E),
          ),
        ),
      ],
    );
  }
}

// ─── Grid Painter ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
