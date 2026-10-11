import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/fade_slide_transition.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../authentication/login_screen.dart';
import '../security/app_lock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeSelector(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Appearance',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.space16),
              ListTile(
                leading: const Icon(Icons.settings_brightness_rounded),
                title: const Text('System Default'),
                trailing: themeProvider.themeMode == ThemeMode.system
                    ? Icon(Icons.check_circle_rounded, color: colors.primaryColor)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: const Text('Light Mode'),
                trailing: themeProvider.themeMode == ThemeMode.light
                    ? Icon(Icons.check_circle_rounded, color: colors.primaryColor)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark Mode'),
                trailing: themeProvider.themeMode == ThemeMode.dark
                    ? Icon(Icons.check_circle_rounded, color: colors.primaryColor)
                    : null,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change App Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: oldPasswordController,
              label: 'Current Password',
              hint: 'Enter existing password',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: newPasswordController,
              label: 'New Password',
              hint: 'Enter at least 4 characters',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primaryColor),
            onPressed: () async {
              final security = context.read<SecurityProvider>();
              final success = await security.changePassword(
                oldPasswordController.text.trim(),
                newPasswordController.text.trim(),
              );

              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                ToastUtils.showSuccess(context, 'Password updated successfully!');
              } else if (ctx.mounted) {
                ToastUtils.showError(
                  context,
                  security.errorMessage ?? 'Failed to update password',
                );
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0 (Production Release)',
      applicationIcon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.orange500,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
      ),
      children: [
        const SizedBox(height: 10),
        const Text(
          'Selavu is a premium trip expense and group settlement manager designed with decimal-safe precision, real-time Supabase sync, and local biometric security.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();
    final securityProvider = context.watch<SecurityProvider>();

    String themeLabel;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        themeLabel = 'Light';
        break;
      case ThemeMode.dark:
        themeLabel = 'Dark';
        break;
      case ThemeMode.system:
        themeLabel = 'System Default';
        break;
    }

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Appearance Section
              FadeSlideTransition(
                child: Text(
                  'Appearance',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space10),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 60),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.palette_outlined, color: colors.primaryColor),
                    title: const Text('Theme Mode'),
                    subtitle: Text(themeLabel),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showThemeSelector(context),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 2. Security Section
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Security',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space10),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 140),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.fingerprint_rounded, color: colors.primaryColor),
                        title: const Text('Biometric Authentication'),
                        subtitle: Text(
                          securityProvider.isBiometricSupported
                              ? (securityProvider.isBiometricEnabled
                                  ? 'Active'
                                  : 'Available')
                              : 'Not supported on device',
                        ),
                        trailing: Switch(
                          value: securityProvider.isBiometricEnabled,
                          activeThumbColor: colors.primaryColor,
                          onChanged: securityProvider.isBiometricSupported
                              ? (val) async {
                                  await securityProvider.toggleBiometric(val);
                                }
                              : null,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.password_rounded, color: colors.primaryColor),
                        title: const Text('Change App Password'),
                        subtitle: const Text('Update your personal application lock password'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock_outline_rounded, color: colors.errorColor),
                        title: Text('Lock App Now', style: TextStyle(color: colors.errorColor)),
                        subtitle: const Text('Requires biometric or password on next interaction'),
                        onTap: () {
                          securityProvider.lockApp();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AppLockScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 3. Currency & Regional
              FadeSlideTransition(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  'Currency & Cloud Sync',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space10),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 220),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.currency_rupee_rounded, color: colors.primaryColor),
                        title: const Text('Primary Currency'),
                        subtitle: const Text('Indian Rupee (₹) • INR'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primaryColor.withValues(alpha: 0.12),
                            borderRadius: AppDimensions.roundedFull,
                          ),
                          child: Text(
                            'INR (₹)',
                            style: TextStyle(
                              color: colors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          SupabaseService.isConfigured
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: SupabaseService.isConfigured
                              ? colors.successColor
                              : colors.warningColor,
                        ),
                        title: const Text('Supabase Backend'),
                        subtitle: Text(
                          SupabaseService.isConfigured
                              ? 'Connected to PostgreSQL cloud database'
                              : 'Offline/Local mode (Configure .env for cloud sync)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 4. About Selavu
              FadeSlideTransition(
                delay: const Duration(milliseconds: 260),
                child: Text(
                  'About',
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space10),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: colors.primaryColor),
                    title: const Text('About Selavu'),
                    subtitle: const Text('Version 1.0.0 • Production Ready'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAboutDialog(context),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 5. Account Sign Out
              FadeSlideTransition(
                delay: const Duration(milliseconds: 320),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.logout_rounded, color: colors.errorColor),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: colors.errorColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Signed in as ${context.watch<AuthProvider>().userEmail.isNotEmpty ? context.watch<AuthProvider>().userEmail : context.watch<AuthProvider>().userName}',
                      style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.errorColor),
                    onTap: () => _showSignOutDialog(context),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out from your Google account on Selavu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();

              if (context.mounted) {
                ToastUtils.showSuccess(context, 'Signed out successfully');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
