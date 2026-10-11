import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';
import '../services/preferences_service.dart';
import '../services/secure_storage_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final BiometricService _biometricService;
  final PreferencesService _prefs;

  bool _isInitialized = false;
  bool _isUnlocked = false;
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  bool _hasPassword = false;
  String? _errorMessage;

  SecurityProvider({
    required SecureStorageService secureStorage,
    required BiometricService biometricService,
    required PreferencesService prefs,
  })  : _secureStorage = secureStorage,
        _biometricService = biometricService,
        _prefs = prefs;

  bool get isInitialized => _isInitialized;
  bool get isUnlocked => _isUnlocked;
  bool get isBiometricSupported => _isBiometricSupported;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPassword => _hasPassword;
  bool get isSecuritySetupDone => _prefs.isSecuritySetupDone();
  String get securityType => _isBiometricEnabled ? 'biometric' : 'password';
  String? get errorMessage => _errorMessage;

  /// Initializes security states on app startup
  Future<void> init() async {
    _isBiometricSupported = await _biometricService.isBiometricAvailable();
    _isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    _hasPassword = await _secureStorage.hasPassword();
    _isInitialized = true;
    notifyListeners();
  }

  /// Step 1: Create dynamic app password
  Future<bool> createPassword(String password) async {
    if (password.length < 4) {
      _errorMessage = 'Password must be at least 4 characters.';
      notifyListeners();
      return false;
    }

    await _secureStorage.savePassword(password);
    _hasPassword = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Step 2: Enable Fingerprint after password creation
  Future<bool> enableBiometric() async {
    final bool authSuccess = await _biometricService.authenticate(
      reason: 'Verify fingerprint to enable biometric unlock for Selavu',
    );

    if (authSuccess) {
      await _secureStorage.setBiometricEnabled(true);
      await _prefs.setSecuritySetupDone(true);
      _isBiometricEnabled = true;
      _isUnlocked = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Fingerprint verification failed or was cancelled.';
      notifyListeners();
      return false;
    }
  }

  /// Step 2 Option: Skip Fingerprint for now
  Future<void> skipBiometric() async {
    await _secureStorage.setBiometricEnabled(false);
    await _prefs.setSecuritySetupDone(true);
    _isBiometricEnabled = false;
    _isUnlocked = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Unlock using Fingerprint / Biometric
  Future<bool> unlockWithBiometric() async {
    _errorMessage = null;
    final success = await _biometricService.authenticate(
      reason: 'Unlock Selavu with your fingerprint',
    );

    if (success) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Biometric unlock failed.';
      notifyListeners();
      return false;
    }
  }

  /// Unlocks using App Password
  Future<bool> unlockWithPassword(String password) async {
    _errorMessage = null;
    final isCorrect = await _secureStorage.verifyPassword(password);

    if (isCorrect) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Incorrect password. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Changes the app password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final verified = await _secureStorage.verifyPassword(oldPassword);
    if (!verified) {
      _errorMessage = 'Current password is incorrect.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      notifyListeners();
      return false;
    }
    await _secureStorage.savePassword(newPassword);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Setup biometric alias
  Future<bool> setupBiometric() async {
    return await enableBiometric();
  }

  /// Toggles biometric unlock
  Future<bool> toggleBiometric(bool enable) async {
    if (enable) {
      return await enableBiometric();
    } else {
      await _secureStorage.setBiometricEnabled(false);
      _isBiometricEnabled = false;
      notifyListeners();
      return true;
    }
  }

  /// Locks the app
  void lockApp() {
    _isUnlocked = false;
    notifyListeners();
  }
}
