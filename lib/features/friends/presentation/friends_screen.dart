import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/friends_provider.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Friends', style: AppTextStyles.heading1)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.1, end: 0),
                        IconButton(
                          onPressed: () => _showAddFriendSheet(context),
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // My invite code card
                    inviteCode.when(
                      data: (code) => code != null
                          ? InviteCodeCard(code: code)
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .slideY(begin: 0.1, end: 0)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'YOUR CIRCLE',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Friends list
            friendsList.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return FriendTile(friend: friends[index])
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: 400.ms,
                          )
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Failed to load friends',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No friends yet',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Share your invite code or enter a friend\'s code to get started.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendSheet(context),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Add Friend'),
            ),
          ],
        ),
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
