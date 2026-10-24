import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_logo.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

/// Shown when the customer opens the reset link from their email. Supabase
/// has already signed them in for recovery, so this only has to save the new
/// password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _backToSignIn() async {
    // The recovery link signed them in; make them log in with the new password.
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<AuthViewModel>();
    final ok = await vm.updatePassword(
      password: _password.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;

    if (!ok) {
      if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. Please sign in with your new password.'),
      ),
    );
    await _backToSignIn();
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textBody,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: hidden,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textDark,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Center(child: AppLogo(fontSize: 32)),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Choose a new password to keep your\n'
                  'SupaClean account secure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _field(
                label: 'New Password',
                hint: 'Enter your new password',
                controller: _password,
                hidden: _hidePassword,
                onToggle: () =>
                    setState(() => _hidePassword = !_hidePassword),
              ),
              const SizedBox(height: 18),
              _field(
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                controller: _confirm,
                hidden: _hideConfirm,
                onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use at least 8 characters, including uppercase and '
                'lowercase letters and a number.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'RESET PASSWORD',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _backToSignIn,
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
