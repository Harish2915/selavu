import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final PreferencesService _prefs;
  final GoogleSignIn _googleSignIn;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._prefs)
      : _googleSignIn = GoogleSignIn(
          serverClientId: SupabaseService.webClientId,
          scopes: const [
            'email',
            'profile',
            'openid',
          ],
        ) {
    _initAuthListener();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns true if a valid Supabase authenticated session exists
  bool get isLoggedIn {
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      return SupabaseService.client!.auth.currentSession != null;
    }
    return _prefs.isLoggedIn();
  }

  /// Current user's display name
  String get userName {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    return _prefs.getGoogleUserName();
  }

  /// Current user's email
  String get userEmail {
    final user = SupabaseService.currentUser;
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }
    return _prefs.getGoogleUserEmail();
  }

  /// Current user photo URL if available
  String? get userPhotoUrl {
    final user = SupabaseService.currentUser;
    return user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;
  }

  /// Listens to Supabase Auth state changes to keep sessions persistent
  void _initAuthListener() {
    _authSubscription?.cancel();
    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      _authSubscription =
          SupabaseService.client!.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        debugPrint('[Auth] Supabase state changed: $event (User: ${session?.user.email})');

        if (session != null) {
          final user = session.user;
          final name = user.userMetadata?['full_name'] as String? ??
              user.userMetadata?['name'] as String? ??
              'You (Me)';
          final email = user.email ?? '';
          _prefs.setGoogleUser(name: name, email: email);
        } else if (event == AuthChangeEvent.signedOut) {
          _prefs.logout();
        }
        notifyListeners();
      });
    }
  }

  /// Native Google Sign-In with Supabase signInWithIdToken
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      if (client == null) {
        debugPrint('[Auth Error] Supabase client is not ready.');
        _errorMessage = 'Authentication service is initializing. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 1. Native Google Sign-In Prompt
      debugPrint('[Auth] Initiating Google Sign-In with serverClientId: ${SupabaseService.webClientId}');
      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        final errorStr = e.toString();
        debugPrint('[Auth Error] GoogleSignIn exception: $errorStr');

        if (errorStr.contains('10') || errorStr.contains('DEVELOPER_ERROR')) {
          debugPrint('====================================================');
          debugPrint('[Google Auth DEVELOPER_ERROR / Code 10]');
          debugPrint('Likely cause: SHA-1 certificate fingerprint mismatch in Google Cloud Console.');
          debugPrint('App Package Name: com.selavu.app.selavu');
          debugPrint('Debug Keystore SHA-1: 7C:AA:A7:33:3F:97:5A:E5:5E:65:7D:FE:75:58:D2:72:DC:86:CF:A5');
          debugPrint('Android Client ID: ${SupabaseService.androidClientId}');
          debugPrint('Web Client ID: ${SupabaseService.webClientId}');
          debugPrint('====================================================');
          _errorMessage = 'Google sign-in configuration error. Please verify SHA-1 setup.';
        } else if (errorStr.contains('7') || errorStr.contains('NETWORK_ERROR')) {
          debugPrint('[Auth Error] Google network error.');
          _errorMessage = 'Network connection issue. Please check your internet connection.';
        } else if (errorStr.contains('12501') || errorStr.contains('SIGN_IN_CANCELLED')) {
          debugPrint('[Auth] User cancelled Google account picker.');
          _errorMessage = null; // Clean cancellation, no error display needed
        } else {
          _errorMessage = 'Could not connect with Google. Please try again.';
        }

        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. User cancelled sign-in
      if (googleUser == null) {
        debugPrint('[Auth] Sign-in cancelled by user.');
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      // 3. Obtain authentication tokens from Google
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint('[Auth Error] Failed to retrieve Google tokens: $e');
        _errorMessage = 'Failed to retrieve Google credentials. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('[Auth Error] Missing ID Token from Google.');
        debugPrint('Verify that Web Client ID (${SupabaseService.webClientId}) is set as serverClientId.');
        _errorMessage = 'Missing Google ID token. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('[Auth Info] Access token is null/empty; Supabase will verify with ID token.');
      }

      // 4. Exchange tokens with Supabase Auth
      debugPrint('[Auth] Exchanging ID token with Supabase Auth...');
      final AuthResponse response;
      try {
        response = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } on AuthException catch (e) {
        debugPrint('====================================================');
        debugPrint('[Supabase AuthException]: ${e.message} (status: ${e.statusCode})');
        final msg = e.message.toLowerCase();

        if (msg.contains('invalid audience') ||
            msg.contains('aud') ||
            msg.contains('unauthorized client')) {
          debugPrint('Likely cause: Web OAuth Client ID not added to Supabase Authorized Client IDs.');
          debugPrint('Go to Supabase Dashboard -> Authentication -> Providers -> Google -> Authorized Client IDs');
          debugPrint('Add: ${SupabaseService.webClientId}');
          _errorMessage = 'Authentication provider mismatch. Please check Authorized Client IDs.';
        } else if (msg.contains('network') || msg.contains('timeout')) {
          _errorMessage = 'Connection timed out. Please check your internet and try again.';
        } else {
          _errorMessage = 'Authentication failed. Please try again.';
        }
        debugPrint('====================================================');

        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        debugPrint('[Auth Error] Unexpected Supabase error: $e');
        _errorMessage = 'An error occurred during authentication. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 5. Successful Supabase authentication
      if (response.user != null) {
        final user = response.user!;
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            googleUser.displayName ??
            'You (Me)';
        final email = user.email ?? googleUser.email;

        await _prefs.setGoogleUser(name: name, email: email);

        debugPrint('[Auth] Successfully authenticated: $email ($name)');
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Authentication could not be completed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[Auth Error] Unhandled exception: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out from both Supabase Auth and GoogleSignIn
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[Auth] Google sign out note: $e');
    }

    try {
      if (SupabaseService.isConfigured && SupabaseService.client != null) {
        await SupabaseService.client!.auth.signOut();
      }
    } catch (e) {
      debugPrint('[Auth] Supabase sign out note: $e');
    }

    await _prefs.logout();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
