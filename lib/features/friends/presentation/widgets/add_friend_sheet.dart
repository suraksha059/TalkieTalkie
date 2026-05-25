import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/friends_repository.dart';

class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key});

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Text('Add a Friend', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Enter your friend\'s 6-character invite code',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Code input
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: AppTextStyles.inviteCode.copyWith(
                fontSize: 24,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ABCDEF',
                hintStyle: AppTextStyles.inviteCode.copyWith(
                  fontSize: 24,
                  letterSpacing: 6,
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                ),
                errorText: _error,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),

            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addFriend,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Text('Add Friend'),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _addFriend() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = FriendsRepository();
      final friendName = await repo.addFriendByCode(user.uid, code);

      if (friendName != null) {
        HapticUtils.medium();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$friendName added! 🎉'),
            ),
          );
        }
      } else {
        setState(() => _error = 'Code not found or already friends');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
