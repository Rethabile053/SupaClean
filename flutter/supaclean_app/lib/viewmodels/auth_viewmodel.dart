import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  bool needsEmailConfirmation = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True when a Supabase session is saved (survives app restarts).
  bool get isLoggedIn => _client.auth.currentSession != null;

  /// The signed-in user, built from Supabase data (never holds a password).
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return UserModel(
      fullName: (meta['full_name'] ?? '') as String,
      email: user.email ?? '',
      phoneNumber: (meta['phone_number'] ?? '') as String,
      password: '',
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// Signs in with Supabase email + password.
  Future<bool> login({required String email, required String password}) async {
    _setError(null);

    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Please enter your email and password.');
      return false;
    }
    if (!_isValidEmail(email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }

    _setLoading(true);
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _setError(e.message);
      return false;
    } catch (_) {
      _isLoading = false;
      _setError('Could not reach the server.');
      return false;
    }
  }

  /// Creates a Supabase account. Name and phone are saved in user metadata.
  Future<bool> register({required UserModel user, required String confirmPassword}) async {
    _setError(null);
    needsEmailConfirmation = false;

    if (user.fullName.trim().isEmpty) {
      _setError('Please enter your full name.');
      return false;
    }
    if (!_isValidEmail(user.email.trim())) {
      _setError('Please enter a valid email address.');
      return false;
    }
    if (user.phoneNumber.trim().isEmpty) {
      _setError('Please enter your phone number.');
      return false;
    }
    if (user.password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return false;
    }
    if (user.password != confirmPassword) {
      _setError('Passwords do not match.');
      return false;
    }

    _setLoading(true);
    try {
      final res = await _client.auth.signUp(
        email: user.email.trim(),
        password: user.password,
        data: {
          'full_name': user.fullName.trim(),
          'phone_number': user.phoneNumber.trim(),
        },
      );
      // If "Confirm email" is on in Supabase, there is no session yet.
      needsEmailConfirmation = res.session == null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _setError(e.message);
      return false;
    } catch (_) {
      _isLoading = false;
      _setError('Could not reach the server.');
      return false;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    _errorMessage = null;
    notifyListeners();
  }
}
