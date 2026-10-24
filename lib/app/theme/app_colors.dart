import 'package:flutter/material.dart';

/// One set of the app's colors. [light] is the original warm-cream Pooja
/// Pasal design; [dark] keeps the same saffron/maroon character on a deep
/// brown so the brand still reads at night.
class AppPalette {
  final Color primary; // deep maroon: headings, icons, nav
  final Color primaryDark;
  final Color accent; // vivid saffron-orange: CTAs
  final Color accentDark;
  final Color accentLight;
  final Color background; // page background
  final Color surface; // cards, sheets, app bars
  final Color card; // soft tinted fills (chips, image wells)
  final Color text;
  final Color muted;
  final Color border;
  final Color success;
  final Color error;
  final Color khaltiPurple;
  final Color fonepayBlue;
  final Color festivalShivaratri;
  final Color festivalTeej;
  final Color shadow;

  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.success,
    required this.error,
    required this.khaltiPurple,
    required this.fonepayBlue,
    required this.festivalShivaratri,
    required this.festivalTeej,
    required this.shadow,
  });

  static const light = AppPalette(
    primary: Color(0xFF7A1E1E),
    primaryDark: Color(0xFF5C1414),
    accent: Color(0xFFE8590C),
    accentDark: Color(0xFFC24A0A),
    accentLight: Color(0xFFFF8A3D),
    background: Color(0xFFFDF6EE),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFF3E0),
    text: Color(0xFF2B1B12),
    muted: Color(0xFF8C6E5D),
    border: Color(0xFFF0DFC5),
    success: Color(0xFF2E9E44),
    error: Color(0xFFC0392B),
    khaltiPurple: Color(0xFF5C2D91),
    fonepayBlue: Color(0xFF1565C0),
    festivalShivaratri: Color(0xFF3B3B58),
    festivalTeej: Color(0xFFB23A6B),
    shadow: Color(0x14000000),
  );

  static const dark = AppPalette(
    primary: Color(0xFFF08C7E),
    primaryDark: Color(0xFF8E2A24),
    accent: Color(0xFFFF8A3D),
    accentDark: Color(0xFFE8590C),
    accentLight: Color(0xFFFFB27A),
    background: Color(0xFF16100C),
    surface: Color(0xFF221914),
    card: Color(0xFF2E221A),
    text: Color(0xFFF6ECE2),
    muted: Color(0xFFBFA594),
    border: Color(0xFF3B2C22),
    success: Color(0xFF55C46F),
    error: Color(0xFFF0705F),
    khaltiPurple: Color(0xFFB794E6),
    fonepayBlue: Color(0xFF6FA8F0),
    festivalShivaratri: Color(0xFF4A4A6E),
    festivalTeej: Color(0xFFC94F80),
    shadow: Color(0x66000000),
  );
}

/// The colors of the palette in use. `App` switches it with the theme
/// (system, light or dark) and rebuilds the tree, so widgets just read
/// `AppColors.x` and get the right shade.
class AppColors {
  /// Fixed brand colours for surfaces that carry white text (banners,
  /// badges, festival tiles): the same in light and dark so the contrast
  /// never drops.
  static const Color brand = Color(0xFF7A1E1E);
  static const Color brandDeep = Color(0xFF4A1010);
  static const Color saffron = Color(0xFFE8590C);

  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;

  static void use(AppPalette palette) => _palette = palette;

  static bool get isDark => identical(_palette, AppPalette.dark);

  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get accent => _palette.accent;
  static Color get accentDark => _palette.accentDark;
  static Color get accentLight => _palette.accentLight;
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get card => _palette.card;
  static Color get text => _palette.text;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static Color get success => _palette.success;
  static Color get error => _palette.error;
  static Color get khaltiPurple => _palette.khaltiPurple;
  static Color get fonepayBlue => _palette.fonepayBlue;
  static Color get festivalShivaratri => _palette.festivalShivaratri;
  static Color get festivalTeej => _palette.festivalTeej;
  static Color get shadow => _palette.shadow;
}
