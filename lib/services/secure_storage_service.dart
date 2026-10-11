import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  static const String _salt = 'selavu_secure_salt_v1';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  /// Hashes the password using SHA-256 with salt so plain-text is never stored
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Saves the hashed user password
  Future<void> savePassword(String password) async {
    final hashed = _hashPassword(password);
    await _storage.write(key: AppConstants.keyAppPin, value: hashed);
  }

  /// Checks if a password has been created
  Future<bool> hasPassword() async {
    final stored = await _storage.read(key: AppConstants.keyAppPin);
    return stored != null && stored.isNotEmpty;
  }

  /// Validates entered password against stored hashed password
  Future<bool> verifyPassword(String enteredPassword) async {
    final storedHash = await _storage.read(key: AppConstants.keyAppPin);
    if (storedHash == null) return false;
    final enteredHash = _hashPassword(enteredPassword);
    return storedHash == enteredHash;
  }

  /// Sets whether biometric authentication is enabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Checks if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: AppConstants.keyBiometricEnabled);
    return val == 'true';
  }

  /// Clears security credentials
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
