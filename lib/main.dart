import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/security_provider.dart';
import 'providers/settlement_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trip_provider.dart';
import 'repositories/expense_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'repositories/payment_repository.dart';
import 'repositories/trip_repository.dart';
import 'services/biometric_service.dart';
import 'services/preferences_service.dart';
import 'services/secure_storage_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables securely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("[Config] .env loading info: $e");
  }

  // Set system UI and orientation preferences
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Initialize Local Preferences
  final prefsService = await PreferencesService.init();

  // 2. Initialize Supabase Backend (Auth Connection)
  await SupabaseService.initialize();

  // 3. Initialize Security & Biometrics
  final secureStorage = SecureStorageService();
  final biometricService = BiometricService();
  final securityProvider = SecurityProvider(
    secureStorage: secureStorage,
    biometricService: biometricService,
    prefs: prefsService,
  );
  await securityProvider.init();

  // 4. Initialize Repositories (Pure Local State / In-Memory ready for Supabase later)
  final tripRepository = TripRepository(prefsService);
  final expenseRepository = ExpenseRepository(prefsService);
  final paymentRepository = PaymentRepository(prefsService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefsService)),
        ChangeNotifierProvider.value(value: securityProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefsService)),
        ChangeNotifierProvider(create: (_) => TripProvider(tripRepository)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(expenseRepository)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(paymentRepository)),
        ChangeNotifierProvider(create: (_) => SettlementProvider()),
      ],
      child: const SelavuApp(),
    ),
  );
}

class SelavuApp extends StatelessWidget {
  const SelavuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
