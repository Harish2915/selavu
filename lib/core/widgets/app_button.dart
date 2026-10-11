import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

enum ButtonVariant { primary, secondary, outline, text }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 52,
    this.customColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;
    Gradient? gradient;

    switch (widget.variant) {
      case ButtonVariant.primary:
        bgColor = widget.customColor ?? colors.primaryColor;
        fgColor = Colors.white;
        gradient = widget.customColor == null ? colors.primaryGradient : null;
        break;
      case ButtonVariant.secondary:
        bgColor = colors.primaryColor.withValues(alpha: 0.12);
        fgColor = colors.primaryColor;
        break;
      case ButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = colors.primaryColor;
        border = Border.all(color: colors.primaryColor, width: 1.5);
        break;
      case ButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = colors.primaryColor;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppDimensions.space10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fgColor),
          const SizedBox(width: AppDimensions.space8),
        ],
        Text(
          widget.text,
          style: AppTypography.labelLarge.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.55,
          child: Container(
            width: widget.isFullWidth ? double.infinity : widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient == null ? bgColor : null,
              gradient: gradient,
              borderRadius: AppDimensions.roundedMD,
              border: border,
              boxShadow: widget.variant == ButtonVariant.primary && isEnabled
                  ? AppDimensions.orangeGlow
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
