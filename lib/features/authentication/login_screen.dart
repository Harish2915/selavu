import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../providers/auth_provider.dart';
import '../home/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return; // Disable repeated taps during login

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      ToastUtils.showSuccess(context, 'Signed in successfully with Google');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secondaryAnim) => const MainNavigationScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ToastUtils.showError(
        context,
        authProvider.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authProvider = context.watch<AuthProvider>();

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

              // Center Branding
              FadeSlideTransition(
                direction: SlideDirection.down,
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: AppDimensions.orangeGlow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colors.primaryColor,
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space28),
                    Text(
                      'Welcome to ${AppConstants.appName}',
                      style: AppTypography.displayMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      'Track every expense.\nEnjoy every trip.',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Google Sign-In Action (ONLY Google Authentication)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _buildGoogleSignInButton(
                      isLoading: authProvider.isLoading,
                      onPressed: _handleGoogleSignIn,
                      colors: colors,
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    Text(
                      'By continuing, you agree to Selavu Terms & Privacy',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.7),
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

  Widget _buildGoogleSignInButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required SelavuColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppDimensions.roundedMD,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: AppDimensions.roundedMD,
            border: Border.all(color: colors.borderColor, width: 1.2),
            boxShadow: AppDimensions.softShadow(),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google 'G' icon badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: colors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Text(
                        'Continue with Google',
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
