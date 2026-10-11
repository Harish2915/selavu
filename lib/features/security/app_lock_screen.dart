import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../authentication/login_screen.dart';
import '../home/main_navigation_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoBiometric();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoBiometric() async {
    final security = context.read<SecurityProvider>();
    if (security.isBiometricEnabled && security.isBiometricSupported) {
      _handleBiometricUnlock();
    }
  }

  Future<void> _handleBiometricUnlock() async {
    final security = context.read<SecurityProvider>();
    final success = await security.unlockWithBiometric();
    if (success && mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _handlePasswordUnlock() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ToastUtils.showError(context, 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);
    final security = context.read<SecurityProvider>();
    final success = await security.unlockWithPassword(password);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _navigateToNextScreen();
    } else if (mounted) {
      ToastUtils.showError(
        context,
        security.errorMessage ?? 'Incorrect password. Try again.',
      );
    }
  }

  void _navigateToNextScreen() {
    final auth = context.read<AuthProvider>();
    // Later launches: If valid Supabase session exists -> Home, otherwise -> Google Login
    final destination = auth.isLoggedIn
        ? const MainNavigationScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => destination,
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppDimensions.space16),

              // Header Branding
              FadeSlideTransition(
                direction: SlideDirection.down,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppDimensions.orangeGlow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    Text(
                      AppConstants.appName,
                      style: AppTypography.displayMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      'Enter your password to unlock',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Password Entry Card
              FadeSlideTransition(
                delay: const Duration(milliseconds: 150),
                child: AppCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _passwordController,
                        label: 'App Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      AppButton(
                        text: 'Unlock',
                        icon: Icons.lock_open_rounded,
                        isLoading: _isLoading,
                        onPressed: _handlePasswordUnlock,
                      ),
                      if (security.isBiometricEnabled && security.isBiometricSupported) ...[
                        const SizedBox(height: AppDimensions.space16),
                        OutlinedButton.icon(
                          onPressed: _handleBiometricUnlock,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Unlock with Fingerprint'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryColor,
                            side: BorderSide(color: colors.primaryColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space20,
                              vertical: AppDimensions.space12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        ),
      ),
    );
  }
}
