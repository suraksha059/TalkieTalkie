import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/friends_provider.dart';
import '../models/friend_model.dart';
import 'widgets/friend_tile.dart';
import 'widgets/add_friend_sheet.dart';
import 'widgets/invite_code_card.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsList = ref.watch(friendsListProvider);
    final inviteCode = ref.watch(myInviteCodeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Friends',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Your walkie-talkie circle',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const Spacer(),
                    // Add friend button
                    GestureDetector(
                      onTap: () => _showAddFriendSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4A42E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),
          ),

          // ── Invite Code Card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: inviteCode.when(
                data: (code) => code != null
                    ? _InviteCodeBanner(code: code)
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                children: [
                  Text(
                    'YOUR CIRCLE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF484F58),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  friendsList.when(
                    data: (list) => Text(
                      '${list.length} friend${list.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF484F58)),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // ── Friends list ─────────────────────────────────────────────
          friendsList.when(
            data: (friends) {
              if (friends.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onAddFriend: () => _showAddFriendSheet(context)),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return _FriendCard(friend: friends[index])
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 80 * index), duration: 400.ms)
                        .slideY(begin: 0.08, end: 0);
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Failed to load friends', style: AppTextStyles.bodyMedium)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddFriendSheet(),
    );
  }
}

// ─── Invite Code Banner ──────────────────────────────────────────────────────

class _InviteCodeBanner extends StatelessWidget {
  final String code;
  const _InviteCodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.15),
            const Color(0xFF00E5FF).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Invite Code', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E), fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  code,
                  style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 4),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF21262D),
                  content: Text('Code copied!', style: GoogleFonts.inter(color: Colors.white)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF8B949E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Friend Card ─────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  final FriendModel friend;
  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: friend.isOnline
              ? AppColors.online.withValues(alpha: 0.25)
              : const Color(0xFF21262D),
          width: 1.5,
        ),
      ),
      child: FriendTile(friend: friend),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddFriend;
  const _EmptyState({required this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
              ),
              child: const Icon(Icons.people_outline_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No friends yet', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Share your invite code or enter a friend\'s code to get started.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAddFriend,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4A42E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Add Friend', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
