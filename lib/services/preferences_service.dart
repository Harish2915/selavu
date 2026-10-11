import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // --- First Launch & Security Flow ---
  bool isSecuritySetupDone() {
    return _prefs.getBool('selavu_security_setup_done') ?? false;
  }

  Future<void> setSecuritySetupDone(bool value) async {
    await _prefs.setBool('selavu_security_setup_done', value);
  }

  // --- Google Authentication State ---
  bool isLoggedIn() {
    return _prefs.getBool('selavu_is_logged_in') ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool('selavu_is_logged_in', value);
  }

  String getGoogleUserName() {
    return _prefs.getString('selavu_google_user_name') ?? 'You (Me)';
  }

  String getGoogleUserEmail() {
    return _prefs.getString('selavu_google_user_email') ?? '';
  }

  Future<void> setGoogleUser({required String name, required String email}) async {
    await _prefs.setString('selavu_google_user_name', name);
    await _prefs.setString('selavu_google_user_email', email);
    await setLoggedIn(true);
  }

  Future<void> logout() async {
    await _prefs.setBool('selavu_is_logged_in', false);
  }

  // --- Theme Mode ---
  ThemeMode getThemeMode() {
    final value = _prefs.getString(AppConstants.keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs.setString(AppConstants.keyThemeMode, value);
  }

  // --- Currency ---
  String getCurrencySymbol() {
    return _prefs.getString(AppConstants.keyCurrencySymbol) ??
        AppConstants.defaultCurrencySymbol;
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await _prefs.setString(AppConstants.keyCurrencySymbol, symbol);
  }

  // --- Local Data Store (In-Memory/Offline-First Cache) ---
  List<Map<String, dynamic>> getLocalTrips() {
    final raw = _prefs.getString('selavu_local_trips');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalTrips(List<Map<String, dynamic>> trips) async {
    await _prefs.setString('selavu_local_trips', jsonEncode(trips));
  }

  List<Map<String, dynamic>> getLocalMembers(String tripId) {
    final raw = _prefs.getString('selavu_local_members_$tripId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalMembers(String tripId, List<Map<String, dynamic>> members) async {
    await _prefs.setString('selavu_local_members_$tripId', jsonEncode(members));
  }

  List<Map<String, dynamic>> getLocalExpenses(String tripId) {
    final raw = _prefs.getString('selavu_local_expenses_$tripId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalExpenses(String tripId, List<Map<String, dynamic>> expenses) async {
    await _prefs.setString('selavu_local_expenses_$tripId', jsonEncode(expenses));
  }

  List<Map<String, dynamic>> getLocalPayments(String tripId) {
    final raw = _prefs.getString('selavu_local_payments_$tripId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalPayments(String tripId, List<Map<String, dynamic>> payments) async {
    await _prefs.setString('selavu_local_payments_$tripId', jsonEncode(payments));
  }
}
