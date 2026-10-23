import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../services/checkout_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'payment_submitted_screen.dart';
import 'upload_proof_screen.dart';

/// What happens when the customer presses Pay:
///
/// - bank transfer, or any delivery order (its fee is paid by EFT):
///   Upload Proof, then the order and payment(s) are sent
/// - cash on collection: the order is sent straight away
///
/// then the Thank-you screen. Errors are thrown as ApiException so the
/// caller (the Pay button, or the Upload Proof screen) can show them.
Future<void> runCheckout(
  BuildContext context, {
  required OrderDraft draft,
  required BookingDetails booking,
  required PaymentMethod method,
}) async {
  final user = context.read<AuthViewModel>().currentUser;
  final navigator = Navigator.of(context);
  final service = CheckoutService();

  Future<void> send(XFile? proof) => service.place(
        draft: draft,
        booking: booking,
        method: method,
        user: user,
        proof: proof,
      );

  if (CheckoutService.needsProof(draft, method)) {
    final sent = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => UploadProofScreen(
          amountDue: method == PaymentMethod.eft ? draft.total : draft.deliveryFee,
          onSubmit: send,
        ),
      ),
    );
    if (sent != true) return;
  } else {
    await send(null);
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => PaymentSubmittedScreen(
        draft: draft,
        booking: booking,
        method: method,
      ),
    ),
    (route) => route.isFirst,
  );
}
