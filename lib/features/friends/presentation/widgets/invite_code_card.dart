import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../../../../core/utils/haptic_utils.dart';

class InviteCodeCard extends StatelessWidget {
  final String code;

  const InviteCodeCard({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR INVITE CODE',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            InviteCodeGenerator.format(code),
            style: AppTextStyles.inviteCode,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionChip(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () {
                  HapticUtils.light();
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied! 📋')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _ActionChip(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () {
                  HapticUtils.light();
                  Share.share(
                    'Join me on TalkShow! 🎙️\nUse my invite code: $code',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
