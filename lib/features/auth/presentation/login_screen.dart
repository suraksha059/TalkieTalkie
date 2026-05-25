import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo / Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'TalkShow',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 40,
                    letterSpacing: -1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Hold. Talk. Connect.\nInstant voice, zero friction.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const Spacer(flex: 2),

                // Sign in buttons
                if (isLoading)
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  )
                else ...[
                  SocialLoginButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () => _signInWithGoogle(context, ref),
                    gradient: AppColors.primaryGradient,
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 14),

                  SocialLoginButton(
                    label: 'Continue with Apple',
                    icon: Icons.apple_rounded,
                    onPressed: () {
                      // TODO: Implement Apple Sign-In
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Apple Sign-In coming soon!'),
                        ),
                      );
                    },
                    outlined: true,
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ],

                const Spacer(),

                // Footer
                Text(
                  'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
