import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          autofocus: autofocus,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTypography.bodyLarge.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
            prefixIcon: prefixWidget ??
                (prefixIcon != null
                    ? Icon(prefixIcon, color: colors.primaryColor, size: 20)
                    : null),
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: colors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: AppDimensions.roundedMD,
              borderSide: BorderSide(color: colors.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppDimensions.roundedMD,
              borderSide: BorderSide(color: colors.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppDimensions.roundedMD,
              borderSide: BorderSide(color: colors.primaryColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppDimensions.roundedMD,
              borderSide: BorderSide(color: colors.errorColor, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
