import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_logo.dart';
import '../widgets/primary_button.dart';

/// Asks for the account's email and has Supabase send a reset link.
/// The link opens the app on [ResetPasswordScreen].
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<AuthViewModel>();
    final ok = await vm.sendPasswordReset(_email.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
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
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _sent
                      ? 'We sent a reset link to ${_email.text.trim()}. '
                          'Open it on this phone to choose a new password.'
                      : "Enter the email you signed up with and we'll send "
                          'you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_sent) ...[
                const Text(
                  'Email Address',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'Enter your email address',
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: 'SEND RESET LINK',
                  isLoading: isLoading,
                  onPressed: _send,
                ),
              ] else ...[
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Can't find it? Check your spam folder.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'SEND AGAIN',
                  isLoading: isLoading,
                  onPressed: _send,
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
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
