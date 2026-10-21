import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

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

  /// Validates credentials, simulates an API call, stores the user on success.
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
    await Future.delayed(const Duration(seconds: 2)); // simulate network
    _setLoading(false);

    // TODO: replace with real authentication (e.g. Supabase/Firebase).
    _currentUser = UserModel(
      fullName: ' ',
      email: email.trim(),
      phoneNumber: '27 75 238 6065',
      password: '',
    );
    return true;
  }

  /// Validates the registration form, simulates an API call.
  Future<bool> register({required UserModel user, required String confirmPassword}) async {
    _setError(null);

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
    await Future.delayed(const Duration(seconds: 2)); // simulate network
    _setLoading(false);

    _currentUser = user;
    return true;
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
