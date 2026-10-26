import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';

/// Look of a product family: an icon and a two-tone gradient. Used for
/// category tiles and for product artwork when a product has no photo, so
/// a catalogue without photos still reads as distinct, intentional items
/// rather than a wall of identical placeholders.
class CategoryVisual {
  final IconData icon;
  final Color from;
  final Color to;

  const CategoryVisual(this.icon, this.from, this.to);

  static const _kits =
      CategoryVisual(Icons.card_giftcard, Color(0xFFFFB36B), Color(0xFFE8590C));
  static const _flowers =
      CategoryVisual(Icons.local_florist, Color(0xFFFFC94D), Color(0xFFF08A24));
  static const _incense =
      CategoryVisual(Icons.spa, Color(0xFFC9A6E8), Color(0xFF7D4FB0));
  static const _brass = CategoryVisual(
      Icons.emoji_objects_outlined, Color(0xFFF2D27A), Color(0xFFB8872A));
  static const _idols =
      CategoryVisual(Icons.temple_hindu, Color(0xFFF59E8B), Color(0xFF9C2A2A));
  static const _prasad = CategoryVisual(
      Icons.cookie_outlined, Color(0xFFF7C59F), Color(0xFFC2703D));
  static const _diyas = CategoryVisual(
      Icons.local_fire_department, Color(0xFFFFD08A), Color(0xFFE2571E));
  static const _other =
      CategoryVisual(Icons.auto_awesome, Color(0xFFF5B9A0), Color(0xFF7A1E1E));

  /// Picks the visual from the category name, falling back to keywords in
  /// [hint] (usually the product name) for lines that don't carry a
  /// category, like cart and order items.
  static CategoryVisual of(String category, {String hint = ''}) {
    // The real category decides when it is known; name keywords are only
    // the fallback (cart and order lines carry no category).
    final fromCategory = _match(category.toLowerCase());
    return identical(fromCategory, _other)
        ? _match(hint.toLowerCase())
        : fromCategory;
  }

  static CategoryVisual _match(String text) {
    if (text.isEmpty) return _other;
    bool has(List<String> words) => words.any(text.contains);
    // Order matters: "agarbatti" must hit incense before "batti" hits diyas.
    if (has(['incense', 'agarbatti', 'dhoop', 'sandal', 'camphor', 'kapur']))
      return _incense;
    if (has(['pooja kit', ' kit', 'kit ', 'thali', 'samagri set']))
      return _kits;
    if (has(['diya', 'diyo', 'lamp', 'batti', 'candle'])) return _diyas;
    if (has(['flower', 'garland', 'lotus', 'marigold', 'sayapatri']))
      return _flowers;
    if (has(['idol', 'murti', 'ganesh', 'shiva', 'lingam', 'laxmi', 'statue']))
      return _idols;
    if (has(['brass', 'kalash', 'copper', 'bell', 'ghanti'])) return _brass;
    if (has(['prasad', 'sweet', 'roti', 'laddu', 'fruit'])) return _prasad;
    return _other;
  }
}

/// A product's photo, or — when it has none or the photo fails — artwork in
/// its category's colours. Photos are cached on the device.
class ProductImage extends StatelessWidget {
  final String url;
  final String category;
  final String name;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  /// Icon size as a fraction of the shorter side.
  final double iconScale;

  const ProductImage({
    super.key,
    required this.url,
    this.category = '',
    this.name = '',
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.iconScale = 0.36,
  });

  @override
  Widget build(BuildContext context) {
    final artwork = _Artwork(
        visual: CategoryVisual.of(category, hint: name), iconScale: iconScale);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: url.isEmpty
            ? artwork
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => artwork,
                errorWidget: (_, __, ___) => artwork,
              ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final CategoryVisual visual;
  final double iconScale;

  const _Artwork({required this.visual, required this.iconScale});

  @override
  Widget build(BuildContext context) {
    // Softer in dark mode so the tiles don't glare against the page.
    final alpha = AppColors.isDark ? 0.72 : 0.9;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide.isFinite
            ? constraints.biggest.shortestSide
            : 80.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                visual.from.withValues(alpha: alpha * 0.8),
                visual.to.withValues(alpha: alpha),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A large faint echo of the icon for texture.
              Positioned(
                right: -side * 0.12,
                bottom: -side * 0.14,
                child: Icon(visual.icon,
                    size: side * 0.75,
                    color: Colors.white.withValues(alpha: 0.14)),
              ),
              Center(
                child: Container(
                  padding: EdgeInsets.all(side * 0.08),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  child: Icon(visual.icon,
                      size: side * iconScale,
                      color: Colors.white.withValues(alpha: 0.95)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A category's icon on its gradient, as a rounded tile (home quick links,
/// the categories grid).
class CategoryBadge extends StatelessWidget {
  final String category;
  final double size;
  final IconData? icon;

  const CategoryBadge(
      {super.key, required this.category, this.size = 48, this.icon});

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisual.of(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [visual.from, visual.to],
        ),
        boxShadow: [
          BoxShadow(
              color: visual.to.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon ?? visual.icon, color: Colors.white, size: size * 0.48),
    );
  }
}
