import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/trip_provider.dart';
import '../authentication/login_screen.dart';
import '../home/main_navigation_screen.dart';
import '../security/app_lock_screen.dart';
import '../security/create_password_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bgFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 1. Ambient background fade-in (0.0 -> 0.3)
    _bgFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    // 2. Logo scale & fade (0.15 -> 0.6)
    _logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.5, curve: Curves.easeIn),
    );

    // 3. Small smooth floating movement (0.4 -> 0.95)
    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward().then((_) => _onAnimationFinished());
  }

  Future<void> _onAnimationFinished() async {
    if (!mounted) return;

    final security = context.read<SecurityProvider>();
    final auth = context.read<AuthProvider>();
    final tripProvider = context.read<TripProvider>();

    // Load initial trip data in background (local in-memory/state)
    tripProvider.loadTrips();

    Widget destination;

    // Requirement 11: Opening Flow
    // 1. First launch security setup (Create Password -> Enable Fingerprint)
    if (!security.isSecuritySetupDone || !security.hasPassword) {
      destination = const CreatePasswordScreen();
    }
    // 2. Later launches: App Lock (Fingerprint or App Password)
    else if (!security.isUnlocked) {
      destination = const AppLockScreen();
    }
    // 3. Unlocked but no valid Supabase session: Google Login
    else if (!auth.isLoggedIn) {
      destination = const LoginScreen();
    }
    // 4. Authenticated & Unlocked: Home Screen
    else {
      destination = const MainNavigationScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => destination,
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: AppDimensions.durationNormal,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _bgFadeAnimation,
            child: Stack(
              children: [
                // Subtle warm orange ambient background glow
                Positioned(
                  top: -120,
                  right: -100,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.primaryColor.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.primaryColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Center Logo without text underneath (as required)
                Center(
                  child: SlideTransition(
                    position: _floatAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: AppDimensions.orangeGlow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  gradient: colors.primaryGradient,
                                  borderRadius: BorderRadius.circular(34),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
