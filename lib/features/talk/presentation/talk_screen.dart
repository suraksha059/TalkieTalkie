import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Ambient glow — changes color based on state
          Positioned(
            top: -size.height * 0.2,
            left: -size.width * 0.3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: size.width * 1.2,
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _stateGlowColor(talkState.state).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      // App icon + name
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/talkie_icon.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Talkie',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const Spacer(),
                      ConnectionStatusBadge(state: talkState.state),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _showLogoutDialog(context, ref),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Color(0xFF8B949E), size: 18),
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Friend selector ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: selectedFriend != null
                      ? _SelectedFriendCard(
                          name: selectedFriend.displayName,
                          photoUrl: selectedFriend.photoUrl,
                          isOnline: selectedFriend.isOnline,
                          onClear: () => ref.read(selectedFriendProvider.notifier).state = null,
                        )
                      : _NoFriendCard(ref: ref),
                ),

                const Spacer(),

                // ── Voice wave ───────────────────────────────────────────
                if (talkState.state == TalkState.talking || talkState.state == TalkState.receiving)
                  const VoiceWaveAnimation()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                // ── Status chip ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _StatusChip(talkState: talkState),
                ),

                const Spacer(),

                // ── Talk button ──────────────────────────────────────────
                TalkButton(
                  isEnabled: selectedFriend != null,
                  talkState: talkState.state,
                  isLocked: talkState.isLocked,
                  onTalkStart: () => ref.read(talkSessionProvider.notifier).startTalking(),
                  onTalkEnd: () => ref.read(talkSessionProvider.notifier).stopTalking(),
                  onLock: () => ref.read(talkSessionProvider.notifier).setLocked(true),
                ),

                const SizedBox(height: 14),

                // ── Hint ─────────────────────────────────────────────────
                Text(
                  talkState.isLocked
                      ? 'Double tap to stop'
                      : talkState.state == TalkState.idle
                          ? selectedFriend != null ? 'Hold to talk' : 'Select a friend first'
                          : talkState.state == TalkState.talking
                              ? 'Release to stop · Slide up to lock'
                              : '',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E)),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stateGlowColor(TalkState state) {
    switch (state) {
      case TalkState.talking:
        return AppColors.primary;
      case TalkState.receiving:
        return AppColors.accent;
      case TalkState.connecting:
        return AppColors.warning;
      case TalkState.error:
        return AppColors.error;
      case TalkState.idle:
        return AppColors.primary;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: AppTextStyles.heading3),
        content: Text('Are you sure you want to sign out from Talkie?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authRepositoryProvider).signOut();
            },
            child: Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Selected Friend Card ────────────────────────────────────────────────────

class _SelectedFriendCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool isOnline;
  final VoidCallback onClear;

  const _SelectedFriendCard({
    required this.name,
    required this.photoUrl,
    required this.isOnline,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppColors.online.withValues(alpha: 0.4)
              : const Color(0xFF21262D),
          width: 1.5,
        ),
        boxShadow: isOnline
            ? [BoxShadow(color: AppColors.online.withValues(alpha: 0.12), blurRadius: 20, spreadRadius: 2)]
            : null,
      ),
      child: Row(
        children: [
          // Avatar with online ring
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline ? AppColors.online : const Color(0xFF30363D),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF21262D),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(name[0].toUpperCase(), style: AppTextStyles.heading3.copyWith(color: AppColors.primary))
                      : null,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D1117), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  isOnline ? '● Online' : '○ Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline ? AppColors.online : const Color(0xFF8B949E),
                  ),
                ),
              ],
            ),
          ),
          // Clear button
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF8B949E)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }
}

// ─── No Friend Card ──────────────────────────────────────────────────────────

class _NoFriendCard extends ConsumerWidget {
  final WidgetRef ref;
  const _NoFriendCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final friendsList = widgetRef.watch(friendsListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF21262D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No friend selected', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('Tap a friend below to start', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E))),
                ],
              ),
            ],
          ),
          friendsList.when(
            data: (friends) {
              if (friends.isEmpty) return const SizedBox(height: 4);
              return Column(
                children: [
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: friends.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return GestureDetector(
                          onTap: () => ref.read(selectedFriendProvider.notifier).state = friend,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF21262D),
                                    backgroundImage: friend.photoUrl.isNotEmpty ? NetworkImage(friend.photoUrl) : null,
                                    child: friend.photoUrl.isEmpty
                                        ? Text(friend.displayName[0].toUpperCase(), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary))
                                        : null,
                                  ),
                                  if (friend.isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.online,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF0D1117), width: 1.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                friend.displayName.split(' ').first,
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B949E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TalkSessionState talkState;
  const _StatusChip({required this.talkState});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData? icon;

    switch (talkState.state) {
      case TalkState.idle:
        return const SizedBox(height: 28);
      case TalkState.connecting:
        text = 'Connecting...';
        color = AppColors.warning;
        icon = Icons.sync_rounded;
      case TalkState.talking:
        text = 'Talking to ${talkState.peerName ?? 'friend'}';
        color = AppColors.primary;
        icon = Icons.mic_rounded;
      case TalkState.receiving:
        text = 'Incoming voice';
        color = AppColors.accent;
        icon = Icons.volume_up_rounded;
      case TalkState.error:
        text = talkState.errorMessage ?? 'Connection error';
        color = AppColors.error;
        icon = Icons.error_outline_rounded;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
