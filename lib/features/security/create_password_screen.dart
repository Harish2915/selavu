import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/security_provider.dart';
import 'enable_fingerprint_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty) {
      ToastUtils.showError(context, 'Please enter a password');
      return;
    }

    if (password.length < 4) {
      ToastUtils.showError(context, 'Password must be at least 4 characters');
      return;
    }

    if (password != confirm) {
      ToastUtils.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final security = context.read<SecurityProvider>();
    final success = await security.createPassword(password);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secondaryAnim) => const EnableFingerprintScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else if (mounted) {
      ToastUtils.showError(context, security.errorMessage ?? 'Failed to save password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space16),
              // App Logo / Shield Icon
              FadeSlideTransition(
                direction: SlideDirection.down,
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppDimensions.orangeGlow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colors.primaryColor,
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space28),

              // Title and Subtitle
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Secure Your Selavu',
                        style: AppTypography.displayMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Create a password to protect\nyour expense information.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),

              // Password Form Card
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: AppCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your app password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      AppTextField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: _obscureConfirm,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space40),

              // Continue Button
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: AppButton(
                  text: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
