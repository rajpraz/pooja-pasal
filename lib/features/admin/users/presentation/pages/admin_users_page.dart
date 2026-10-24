import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/admin/users/presentation/providers/admin_user_providers.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Read-only user directory. Role changes are never made from this list —
/// see `admin_user_detail_page.dart` for the one gated promote-to-admin
/// action, and `admin_seller_detail_page.dart` for seller demote/restore.
/// No PII beyond what's already on [AppUser] (name/email/phone/role/join
/// date) is fetched or shown.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _query = '';

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'seller':
        return AppColors.khaltiPurple;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or email',
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load users: $err')),
        data: (users) {
          final filtered = _query.isEmpty
              ? users
              : users
                  .where((u) =>
                      u.name.toLowerCase().contains(_query) ||
                      u.email.toLowerCase().contains(_query))
                  .toList();

          if (filtered.isEmpty) {
            return const EmptyView(
              icon: Icons.people_outline,
              title: 'No users found',
              subtitle: 'Try a different search.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final AppUser user = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.card,
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child:
                        user.photoUrl.isEmpty ? Icon(Icons.person, color: AppColors.primary) : null,
                  ),
                  title: Text(user.name.isEmpty ? '(no name)' : user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(user.email, style: TextStyle(color: AppColors.muted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roleColor(user.role).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user.role.toUpperCase(),
                        style: TextStyle(
                            color: _roleColor(user.role),
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  onTap: () => context.push(RouteNames.adminUserDetailPath(user.uid)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
