import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBorder = border ??
        Border.all(
          color: colors.borderColor,
          width: 1,
        );

    final cardRadius = borderRadius ?? AppDimensions.roundedLG;

    Widget cardWidget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colors.cardColor) : null,
        gradient: gradient,
        borderRadius: cardRadius,
        border: gradient == null ? cardBorder : null,
        boxShadow: boxShadow ?? AppDimensions.cardShadow(isDark: isDark),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardRadius,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
