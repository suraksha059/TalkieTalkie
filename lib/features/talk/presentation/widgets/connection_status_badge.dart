import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/talk_provider.dart';

/// Small badge showing connection status.
class ConnectionStatusBadge extends StatelessWidget {
  final TalkState state;

  const ConnectionStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == TalkState.idle) {
      return const SizedBox.shrink();
    }

    final (String label, Color color, IconData icon) = switch (state) {
      TalkState.connecting => ('Connecting', AppColors.warning, Icons.sync_rounded),
      TalkState.talking => ('Live', AppColors.online, Icons.mic_rounded),
      TalkState.receiving => ('Incoming', AppColors.accent, Icons.volume_up_rounded),
      TalkState.error => ('Error', AppColors.error, Icons.error_outline_rounded),
      _ => ('', AppColors.textTertiary, Icons.circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
