import 'package:flutter/material.dart';

/// Centralized Color Tokens for Selavu
/// Swiggy-inspired warm orange visual identity with premium Light & Dark variants
class AppColors {
  // Brand Oranges
  static const Color orange50 = Color(0xFFFFF6ED);
  static const Color orange100 = Color(0xFFFFECCF);
  static const Color orange200 = Color(0xFFFFD59E);
  static const Color orange300 = Color(0xFFFFB866);
  static const Color orange400 = Color(0xFFFF9A2E);
  static const Color orange500 = Color(0xFFFC8019); // Swiggy-inspired signature orange
  static const Color orange600 = Color(0xFFE56905);
  static const Color orange700 = Color(0xFFC45000);
  static const Color orange800 = Color(0xFF9E3D00);

  // Accent Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF9233), Color(0xFFFC8019)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeVibrantGradient = LinearGradient(
    colors: [Color(0xFFFF851B), Color(0xFFE05300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF262629), Color(0xFF1E1E22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFFE6FAF5);
  static const Color error = Color(0xFFFF4757);
  static const Color errorLight = Color(0xFFFFECEE);
  static const Color warning = Color(0xFFFFA502);
  static const Color warningLight = Color(0xFFFFF7E6);
  static const Color info = Color(0xFF0984E3);

  // ================= LIGHT PALETTE =================
  static const Color lightPrimary = orange500;
  static const Color lightSecondary = Color(0xFF2B2D42);
  static const Color lightBackground = Color(0xFFF8F9FD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightDivider = Color(0xFFEAEBED);
  static const Color lightBorder = Color(0xFFE2E4E8);

  // ================= DARK PALETTE =================
  static const Color darkPrimary = orange500;
  static const Color darkSecondary = Color(0xFFFFA559);
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1A1A1E);
  static const Color darkCard = Color(0xFF222227);
  static const Color darkTextPrimary = Color(0xFFF5F6FA);
  static const Color darkTextSecondary = Color(0xFF9EA3AC);
  static const Color darkDivider = Color(0xFF2D2E35);
  static const Color darkBorder = Color(0xFF35363F);
}

/// Dynamic theme extension to provide access to Selavu color tokens in any widget:
/// `Theme.of(context).extension<SelavuColors>()!`
class SelavuColors extends ThemeExtension<SelavuColors> {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color dividerColor;
  final Color borderColor;
  final LinearGradient primaryGradient;

  const SelavuColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.dividerColor,
    required this.borderColor,
    required this.primaryGradient,
  });

  static const SelavuColors light = SelavuColors(
    primaryColor: AppColors.lightPrimary,
    secondaryColor: AppColors.lightSecondary,
    backgroundColor: AppColors.lightBackground,
    surfaceColor: AppColors.lightSurface,
    cardColor: AppColors.lightCard,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    successColor: AppColors.success,
    errorColor: AppColors.error,
    warningColor: AppColors.warning,
    dividerColor: AppColors.lightDivider,
    borderColor: AppColors.lightBorder,
    primaryGradient: AppColors.orangeGradient,
  );

  static const SelavuColors dark = SelavuColors(
    primaryColor: AppColors.darkPrimary,
    secondaryColor: AppColors.darkSecondary,
    backgroundColor: AppColors.darkBackground,
    surfaceColor: AppColors.darkSurface,
    cardColor: AppColors.darkCard,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    successColor: AppColors.success,
    errorColor: AppColors.error,
    warningColor: AppColors.warning,
    dividerColor: AppColors.darkDivider,
    borderColor: AppColors.darkBorder,
    primaryGradient: AppColors.orangeVibrantGradient,
  );

  @override
  ThemeExtension<SelavuColors> copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? dividerColor,
    Color? borderColor,
    LinearGradient? primaryGradient,
  }) {
    return SelavuColors(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      dividerColor: dividerColor ?? this.dividerColor,
      borderColor: borderColor ?? this.borderColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  ThemeExtension<SelavuColors> lerp(ThemeExtension<SelavuColors>? other, double t) {
    if (other is! SelavuColors) return this;
    return SelavuColors(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      primaryGradient: primaryGradient,
    );
  }
}

/// Handy extension on BuildContext to quickly access tokens:
/// `context.colors.primaryColor`, `context.colors.textPrimary`, etc.
extension BuildContextColors on BuildContext {
  SelavuColors get colors =>
      Theme.of(this).extension<SelavuColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? SelavuColors.dark
          : SelavuColors.light);
}
