import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';

/// Keeps the phone-first layout readable on tablets, desktops and the web:
/// beyond [maxWidth] the app is centred in a column of that width (and told
/// it is that wide, so grids, sheets and dialogs size themselves for it)
/// instead of stretching every row across the screen.
class ResponsiveFrame extends StatelessWidget {
  static const double maxWidth = 720;

  final Widget child;

  const ResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        final media = MediaQuery.of(context);
        return ColoredBox(
          color: Color.alphaBlend(AppColors.shadow, AppColors.background),
          child: Center(
            child: Container(
              width: maxWidth,
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 24)],
              ),
              child: MediaQuery(
                data: media.copyWith(size: Size(maxWidth, media.size.height)),
                child: ClipRect(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
