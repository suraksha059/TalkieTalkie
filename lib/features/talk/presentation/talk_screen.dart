import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../friends/providers/friends_provider.dart';
import '../providers/talk_provider.dart';
import 'widgets/talk_button.dart';
import 'widgets/voice_wave_animation.dart';
import 'widgets/connection_status_badge.dart';

class TalkScreen extends ConsumerWidget {
  const TalkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talkState = ref.watch(talkSessionProvider);
    final selectedFriend = ref.watch(selectedFriendProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'TalkShow',
                      style: AppTextStyles.heading2,
                    ).animate().fadeIn(duration: 400.ms),
                    const Spacer(),
                    ConnectionStatusBadge(state: talkState.state),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Selected friend info
              if (selectedFriend != null)
                _buildSelectedFriend(
                  selectedFriend.displayName,
                  selectedFriend.photoUrl,
                  selectedFriend.isOnline,
                )
              else
                _buildNoFriendSelected(context, ref),

              const Spacer(),

              // Voice wave animation
              if (talkState.state == TalkState.talking ||
                  talkState.state == TalkState.receiving)
                const VoiceWaveAnimation()
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

              // Status text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildStatusText(talkState),
              ),

              const Spacer(),

              // Talk button
              TalkButton(
                isEnabled: selectedFriend != null,
                talkState: talkState.state,
                isLocked: talkState.isLocked,
                onTalkStart: () {
                  ref.read(talkSessionProvider.notifier).startTalking();
                },
                onTalkEnd: () {
                  ref.read(talkSessionProvider.notifier).stopTalking();
                },
                onLock: () {
                  ref.read(talkSessionProvider.notifier).setLocked(true);
                },
              ),

              const SizedBox(height: 16),

              // Hint text
              Text(
                talkState.isLocked
                    ? 'Double tap to stop'
                    : talkState.state == TalkState.idle
                    ? 'Hold to talk'
                    : talkState.state == TalkState.talking
                    ? 'Release to stop or slide up to lock'
                    : '',
                style: AppTextStyles.bodySmall,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFriend(String name, String photoUrl, bool isOnline) {
    return Column(
      children: [
        // Avatar
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOnline ? AppColors.online : AppColors.surfaceLight,
                  width: 3,
                ),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.online.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name[0].toUpperCase(),
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 12),

        Text(
          name,
          style: AppTextStyles.heading3,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline
                ? AppColors.online.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isOnline ? '● Online' : '○ Offline',
            style: AppTextStyles.bodySmall.copyWith(
              color: isOnline ? AppColors.online : AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildNoFriendSelected(BuildContext context, WidgetRef ref) {
    final friendsList = ref.watch(friendsListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 36,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Select a friend', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            'Choose someone from your friends list to start talking',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),

          // Quick friend selector
          friendsList.when(
            data: (friends) {
              if (friends.isEmpty) return const SizedBox(height: 20);
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: friends.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedFriendProvider.notifier).state =
                              friend;
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.surfaceLight,
                              backgroundImage: friend.photoUrl.isNotEmpty
                                  ? NetworkImage(friend.photoUrl)
                                  : null,
                              child: friend.photoUrl.isEmpty
                                  ? Text(
                                      friend.displayName[0].toUpperCase(),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              friend.displayName.split(' ').first,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatusText(TalkSessionState talkState) {
    String text;
    Color color;

    switch (talkState.state) {
      case TalkState.idle:
        text = '';
        color = AppColors.textTertiary;
      case TalkState.connecting:
        text = 'Connecting...';
        color = AppColors.warning;
      case TalkState.talking:
        text = 'Talking to ${talkState.peerName ?? 'friend'}';
        color = AppColors.primary;
      case TalkState.receiving:
        text = '🎙️ Incoming voice...';
        color = AppColors.accent;
      case TalkState.error:
        text = talkState.errorMessage ?? 'Connection error';
        color = AppColors.error;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Logout', style: AppTextStyles.heading3),
        content: Text(
          'Are you sure you want to logout from TalkShow?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authRepositoryProvider).signOut();
            },
            child: Text(
              'Logout',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
