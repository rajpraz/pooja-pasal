import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/app/theme/theme_mode_provider.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

/// Lets anyone pick light, dark, or follow-the-phone.
Future<void> showAppearanceSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(themeModeProvider);
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 12),
            for (final (mode, icon) in const [
              (ThemeMode.system, Icons.brightness_auto_outlined),
              (ThemeMode.light, Icons.light_mode_outlined),
              (ThemeMode.dark, Icons.dark_mode_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(themeModeLabel(mode)),
                subtitle: mode == ThemeMode.system
                    ? const Text('Match your phone')
                    : null,
                trailing: Icon(
                  mode == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == current ? AppColors.accent : AppColors.muted,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(themeModeProvider.notifier).set(mode);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// App-bar button that opens [showAppearanceSheet] (seller and admin
/// screens, which have no profile page).
class AppearanceButton extends ConsumerWidget {
  const AppearanceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Appearance',
      icon: Icon(AppColors.isDark
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined),
      onPressed: () => showAppearanceSheet(context, ref),
    );
  }
}
