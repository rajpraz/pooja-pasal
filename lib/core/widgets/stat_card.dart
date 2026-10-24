import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';

/// Small icon+value+label stat tile used on dashboard grids (seller,
/// admin). Extracted so both dashboards share one implementation instead
/// of duplicating the same widget tree.
class StatCard extends StatelessWidget {
  /// Height grids should give each card (padding + value + label, with
  /// headroom for larger system fonts).
  static const double height = 84;

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color ?? AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
