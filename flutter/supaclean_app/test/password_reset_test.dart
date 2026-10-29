import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/viewmodels/auth_viewmodel.dart';

void main() {
  test('password rule: 8+ characters with upper, lower and a number', () {
    expect(AuthViewModel.isStrongPassword('Abcdefg1'), isTrue);
    expect(AuthViewModel.isStrongPassword('Abcdef1'), isFalse); // too short
    expect(AuthViewModel.isStrongPassword('abcdefg1'), isFalse); // no upper
    expect(AuthViewModel.isStrongPassword('ABCDEFG1'), isFalse); // no lower
    expect(AuthViewModel.isStrongPassword('Abcdefgh'), isFalse); // no number
  });

  test('the reset link address matches the Android manifest', () {
    expect(AuthViewModel.resetRedirect, 'com.example.supaclean://reset-callback');
  });
}
