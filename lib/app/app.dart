import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/router/app_router.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/app/theme/app_theme.dart';
import 'package:pooja_pasal/app/theme/theme_mode_provider.dart';
import 'package:pooja_pasal/core/services/push_notification_service.dart';
import 'package:pooja_pasal/core/widgets/responsive_frame.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Follows the phone switching between light and dark.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Register for push whenever someone signs in (including a restored
    // session at launch).
    ref.listen(authStateProvider, (previous, next) {
      final wasSignedIn = previous?.value != null;
      if (next.value != null && !wasSignedIn) {
        ref.read(pushNotificationServiceProvider).onSignedIn();
      }
    });

    final mode = ref.watch(themeModeProvider);
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final dark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    // Widgets read AppColors directly, so the palette is switched here and
    // the app below is rebuilt from scratch (the key) when it changes. The
    // router keeps its location across that rebuild.
    AppColors.use(dark ? AppPalette.dark : AppPalette.light);

    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      key: ValueKey(dark),
      debugShowCheckedModeBanner: false,
      title: 'Pooja Pasal',
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          ResponsiveFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
