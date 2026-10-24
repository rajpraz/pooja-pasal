import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/admin/sellers/presentation/providers/admin_seller_providers.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Promoting a buyer/seller straight to admin is a genuinely sensitive
/// action (full backend trust), so it lives here behind an explicit,
/// strongly-worded confirmation rather than being a casual one-tap toggle
/// like seller demote/restore. Uses the same existing `setUserRole` Cloud
/// Function as everything else that changes a role — no new backend
/// surface.
class AdminUserDetailPage extends ConsumerWidget {
  final String uid;

  const AdminUserDetailPage({super.key, required this.uid});

  Future<void> _confirmPromoteToAdmin(BuildContext context, WidgetRef ref, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Grant admin access?'),
        content: Text(
            '"${user.name.isEmpty ? user.email : user.name}" will get full admin access to this app — '
            'user management, order oversight, product/category moderation, and the ability to '
            'promote/demote any other account, including this one. This cannot be undone from this '
            'screen once granted (only another admin, or the manual bootstrap script, can reverse it).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Grant Admin Access', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminSellerControllerProvider.notifier).setRole(uid, 'admin');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Admin access granted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12))),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider(uid));
    final isBusy = ref.watch(adminSellerControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('User Details')),
      body: userDocAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load user: $err')),
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.card,
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty
                        ? Icon(Icons.person, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Name', user.name),
                        _row('Email', user.email),
                        _row('Phone', user.phone),
                        _row('Address', user.address),
                        _row('Role', user.role.toUpperCase()),
                        _row(
                            'Joined',
                            user.createdAt == null
                                ? ''
                                : user.createdAt!.toString().substring(0, 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (user.role != 'admin')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _confirmPromoteToAdmin(context, ref, user),
                      icon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.error),
                      label: Text('Grant Admin Access', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
                    ),
                  )
                else
                  Center(
                    child: Text('This user already has admin access.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
