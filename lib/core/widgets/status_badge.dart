import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

enum BadgeType { active, completed, owes, receives, settled }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.active:
        bg = AppColors.orange500.withValues(alpha: 0.12);
        fg = AppColors.orange500;
        break;
      case BadgeType.completed:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade300
            : Colors.grey.shade700;
        break;
      case BadgeType.receives:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case BadgeType.owes:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case BadgeType.settled:
        bg = AppColors.info.withValues(alpha: 0.12);
        fg = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space10,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimensions.roundedFull,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
