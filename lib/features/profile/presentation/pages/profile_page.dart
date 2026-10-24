import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/app/theme/appearance_sheet.dart';
import 'package:pooja_pasal/app/theme/theme_mode_provider.dart';
import 'package:pooja_pasal/core/widgets/app_bottom_nav.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/profile/presentation/widgets/seller_application_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String language = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('app_language') ?? 'English';
    });
  }

  void _editProfile() {
    context.push(RouteNames.editProfile);
  }

  void _changeLanguage() {
    showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose language'),
        children: ['English', 'नेपाली'].map((lang) {
          return SimpleDialogOption(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('app_language', lang);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() => language = lang);
            },
            child: Text(lang),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(signOutActionProvider)();
    if (!mounted) return;
    context.go(RouteNames.login);
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {String? trailingText}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.accent),
          title: Text(label, style: TextStyle(color: AppColors.text)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(trailingText, style: TextStyle(color: AppColors.muted)),
                ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
            ],
          ),
          onTap: onTap,
        ),
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(currentUserDocProvider);
    final isLoadingProfile = userDocAsync.isLoading && !userDocAsync.hasValue;
    final userName = userDocAsync.value?.name ?? '';
    final userPhone = userDocAsync.value?.phone ?? '';
    final userPhotoUrl = userDocAsync.value?.photoUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                    child: userPhotoUrl.isEmpty
                        ? Icon(Icons.person, size: 34, color: AppColors.accent)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                        const SizedBox(height: 4),
                        if (isLoadingProfile)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Text(userName.isEmpty ? 'Your name' : userName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        if (!isLoadingProfile)
                          Text(userPhone.isEmpty ? 'Add a phone number' : userPhone,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'Edit profile',
                    onPressed: _editProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _tile(Icons.receipt_long_outlined, 'My Orders',
                      () => context.push(RouteNames.orders)),
                  _tile(Icons.favorite_border, 'Wishlist', () => context.push(RouteNames.wishlist)),
                  _tile(Icons.location_on_outlined, 'Addresses',
                      () => context.push(RouteNames.addresses)),
                  _tile(Icons.notifications_none, 'Notifications',
                      () => context.push(RouteNames.notifications)),
                  _tile(
                      Icons.palette_outlined, 'Appearance', () => showAppearanceSheet(context, ref),
                      trailingText: themeModeLabel(ref.watch(themeModeProvider))),
                  _tile(Icons.language_outlined, 'Language', _changeLanguage,
                      trailingText: language),
                  if (userDocAsync.value case final user? when user.role == 'buyer')
                    _tile(
                      Icons.storefront_outlined,
                      'Become a Seller',
                      user.hasPendingSellerApplication
                          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Your seller application is waiting for review.')))
                          : () => showSellerApplicationDialog(context, ref, user),
                      trailingText: switch (user.sellerStatus) {
                        'pending' => 'Pending',
                        'rejected' => 'Declined',
                        _ => null,
                      },
                    ),
                  _tile(Icons.help_outline, 'Help & Support',
                      () => context.push(RouteNames.helpSupport)),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.accent),
                    title: Text('Logout', style: TextStyle(color: AppColors.text)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}
