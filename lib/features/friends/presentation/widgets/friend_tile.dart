import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../models/friend_model.dart';
import '../../providers/friends_provider.dart';

class FriendTile extends ConsumerWidget {
  final FriendModel friend;

  const FriendTile({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticUtils.selection();
            ref.read(selectedFriendProvider.notifier).state = friend;
            context.go('/talk');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: friend.photoUrl.isNotEmpty
                          ? NetworkImage(friend.photoUrl)
                          : null,
                      child: friend.photoUrl.isEmpty
                          ? Text(
                              friend.displayName[0].toUpperCase(),
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: friend.isOnline
                              ? AppColors.online
                              : AppColors.offline,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Name & status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        friend.lastSeenText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: friend.isOnline
                              ? AppColors.online
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Talk action
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: friend.isOnline
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 20,
                    color: friend.isOnline
                        ? AppColors.primary
                        : AppColors.textTertiary,
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
