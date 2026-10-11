import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../providers/security_provider.dart';
import '../authentication/login_screen.dart';

class EnableFingerprintScreen extends StatefulWidget {
  const EnableFingerprintScreen({super.key});

  @override
  State<EnableFingerprintScreen> createState() => _EnableFingerprintScreenState();
}

class _EnableFingerprintScreenState extends State<EnableFingerprintScreen> {
  bool _isLoading = false;

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _handleEnableFingerprint() async {
    final security = context.read<SecurityProvider>();
    setState(() => _isLoading = true);

    final success = await security.enableBiometric();
    setState(() => _isLoading = false);

    if (success && mounted) {
      ToastUtils.showSuccess(context, 'Fingerprint unlock enabled ✓');
      _navigateToLogin();
    } else if (mounted) {
      ToastUtils.showError(
        context,
        security.errorMessage ?? 'Biometric verification failed. You can skip for now.',
      );
    }
  }

  Future<void> _handleSkip() async {
    final security = context.read<SecurityProvider>();
    await security.skipBiometric();
    if (mounted) {
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space28,
            vertical: AppDimensions.space32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppDimensions.space20),

              // Center Visual
              FadeSlideTransition(
                direction: SlideDirection.down,
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        boxShadow: AppDimensions.softShadow(),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 72,
                          color: colors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space32),
                    Text(
                      'Enable Fingerprint',
                      style: AppTypography.displayMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      'Use your fingerprint to quickly\nunlock Selavu.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    AppButton(
                      text: 'Enable Fingerprint',
                      icon: Icons.fingerprint_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleEnableFingerprint,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    TextButton(
                      onPressed: _handleSkip,
                      child: Text(
                        'Skip for Now',
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
